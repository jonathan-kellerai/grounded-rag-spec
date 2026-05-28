# Active Epistemic Systems: Implementation Guide for Matryoshka

**Concrete patterns, pseudocode, and design decisions for building systems that know what they don't know.**

---

## Part 1: Knowledge Gap Detection Pipeline

### 1.1 Abstention Pattern Tracking

Every query that produces low confidence should be logged with structured metadata.

```
abstention_event = {
  query_id: str,
  query_text: str,
  topic: str,  # domain/category
  entity_pairs: list[tuple],  # (entity1, relation, entity2)
  question_type: str,  # "how", "why", "what-if", "who", "when"
  confidence: float,  # model confidence 0-1
  reason: str,  # "no_relevant_context", "multiple_interpretations", "hallucination_detected"
  timestamp: datetime,
  model_version: str,
  user_profile: optional[dict]  # if available
}
```

### 1.2 Clustering Abstentions to Find Gaps

**Algorithm: Temporal + Semantic Clustering**

```python
def detect_knowledge_gaps(abstention_log: list[AbstractionEvent]) -> list[GapCluster]:
    """
    Identify regions of high abstention frequency.
    """
    # Step 1: Extract semantic vectors for each abstention
    semantic_vectors = []
    for event in abstention_log:
        # Combine: topic + entity pairs + question type
        vec = embedding_model(
            f"{event.topic} {event.entity_pairs} {event.question_type}"
        )
        semantic_vectors.append(vec)

    # Step 2: Cluster using density-based approach (HDBSCAN)
    # Look for regions where confidence is consistently < threshold
    low_conf_events = [e for e in abstention_log if e.confidence < 0.6]

    clusters = cluster_by_density(
        vectors=[embedding_model(e.query_text) for e in low_conf_events],
        min_cluster_size=5,  # require at least 5 similar abstentions
        metric='cosine'
    )

    # Step 3: Characterize each cluster
    gap_clusters = []
    for cluster_id, member_indices in clusters.items():
        cluster_events = [low_conf_events[i] for i in member_indices]

        # What do these events have in common?
        common_topic = most_common([e.topic for e in cluster_events])
        common_entities = most_common_entity_pairs([e.entity_pairs for e in cluster_events])
        common_q_type = most_common([e.question_type for e in cluster_events])

        gap_clusters.append(GapCluster(
            id=cluster_id,
            size=len(cluster_events),
            topic=common_topic,
            missing_entity_relations=common_entities,
            question_type=common_q_type,
            frequency_per_week=len(cluster_events) / weeks_elapsed,
            recent_examples=cluster_events[-3:],  # last 3 examples
        ))

    return gap_clusters
```

**Key insight:** Gaps are not uniform. A gap in "error handling" will have different structure from a gap in "API documentation".

### 1.3 Gap Diagnosis: What Kind of Gap?

Once a gap cluster is identified, diagnose the root cause.

```python
class GapType(Enum):
    SEMANTIC = "entities exist, relation missing"
    EPISTEMIC = "concept/entity doesn't exist in corpus"
    CALIBRATION = "corpus has it, system missed it"
    MISCONCEPTION = "user asking wrong question"

def diagnose_gap(gap_cluster: GapCluster) -> GapDiagnosis:
    """
    Determine why the system is failing for this gap cluster.
    """

    diagnosis = GapDiagnosis()

    # Check 1: Semantic gaps (entity relationship missing)
    entities = flatten_entity_pairs(gap_cluster.missing_entity_relations)
    for entity in entities:
        if entity_exists_in_knowledge_base(entity):
            diagnosis.entity_coverage.append(entity)
        else:
            diagnosis.missing_entities.append(entity)

    # Check 2: Epistemic gaps (concept not in corpus)
    topic = gap_cluster.topic
    topic_docs = retrieve_docs_about(topic, top_k=50)

    question_template = generate_template_question(
        topic,
        gap_cluster.question_type
    )

    if not any(answer_question(q, topic_docs) for q in question_template):
        diagnosis.gap_type = GapType.EPISTEMIC
        diagnosis.recommended_source = f"Ingest docs/standards about {topic}"

    # Check 3: Calibration (can answer but model lacks confidence)
    # Test: Re-query with confidence-boosting prompts
    high_conf_answer = requery_with_external_retrieval(gap_cluster.recent_examples[0])
    if high_conf_answer and high_conf_answer.is_correct():
        diagnosis.gap_type = GapType.CALIBRATION
        diagnosis.root_cause = "Model context window too small or embeddings misaligned"

    # Check 4: Misconception (user asking ambiguous question)
    if gap_cluster.question_type in ["what", "how"]:
        paraphrases = generate_paraphrases(gap_cluster.recent_examples[0].query_text)
        if any(paraphrases):  # some paraphrases work
            diagnosis.gap_type = GapType.MISCONCEPTION
            diagnosis.root_cause = f"User likely asking about variant: {paraphrases[0]}"

    return diagnosis
```

### 1.4 Proposal Generation

```python
def generate_gap_proposal(gap_cluster: GapCluster, diagnosis: GapDiagnosis) -> Proposal:
    """
    Create actionable proposal to close the gap.
    """

    proposal = Proposal(
        gap_id=gap_cluster.id,
        priority=gap_cluster.frequency_per_week * impact_score(gap_cluster),
        actions=[]
    )

    if diagnosis.gap_type == GapType.EPISTEMIC:
        # Recommend ingesting new source
        external_source = find_best_source_for(gap_cluster.topic)
        proposal.actions.append(Action(
            type="ingest_source",
            source=external_source,
            description=f"Add {external_source.name} to knowledge base for {gap_cluster.topic}",
            effort="medium"
        ))

    elif diagnosis.gap_type == GapType.SEMANTIC:
        # Recommend enriching entity relations in code graph
        missing_relations = diagnosis.missing_entity_relations
        proposal.actions.append(Action(
            type="enrich_relations",
            relations=missing_relations,
            description=f"Link {missing_relations[0][0]} → {missing_relations[0][2]} in code structure",
            effort="low"
        ))

    elif diagnosis.gap_type == GapType.CALIBRATION:
        # Recommend retraining or prompt engineering
        proposal.actions.append(Action(
            type="improve_confidence_calibration",
            method="prompt_engineering" if diagnosis.root_cause.contains("context") else "rerank",
            description="Increase relevance of retrieved context",
            effort="low"
        ))

    elif diagnosis.gap_type == GapType.MISCONCEPTION:
        # Recommend query clarification flow
        proposal.actions.append(Action(
            type="clarify_query",
            clarification_questions=[
                f"Did you mean: {p}?" for p in diagnosis.paraphrases[:2]
            ],
            description="User likely needs guidance on phrasing",
            effort="minimal"
        ))

    return proposal
```

---

## Part 2: Active Learning Integration (Query by Committee)

### 2.1 Multi-Model Disagreement Detection

```python
class Committee:
    """
    Use multiple models as a "committee" to detect uncertainty through disagreement.
    """

    def __init__(self, models: list[LLM]):
        self.models = models

    def query_all(self, question: str) -> list[Response]:
        """
        Ask all models the same question.
        """
        responses = []
        for model in self.models:
            response = model.answer(question)
            responses.append(response)
        return responses

    def measure_disagreement(self, responses: list[Response]) -> float:
        """
        How much do the models disagree?

        Simple version: BLEU score distance between answers
        Advanced version: Semantic similarity of extracted knowledge
        """
        if len(responses) < 2:
            return 0.0

        # Compute pairwise distances
        distances = []
        for i in range(len(responses)):
            for j in range(i + 1, len(responses)):
                dist = embedding_distance(
                    embedding_model(responses[i].text),
                    embedding_model(responses[j].text)
                )
                distances.append(dist)

        return mean(distances)

    def identify_high_uncertainty_queries(self,
                                         question_candidates: list[str],
                                         threshold: float = 0.5) -> list[str]:
        """
        From a pool of candidates, select those where the committee disagrees most.
        """
        uncertainty_scores = []
        for question in question_candidates:
            responses = self.query_all(question)
            disagreement = self.measure_disagreement(responses)
            uncertainty_scores.append((question, disagreement))

        # Return questions with highest disagreement
        return [q for q, score in uncertainty_scores if score > threshold]
```

### 2.2 Adaptive Question Generation

```python
def generate_clarifying_questions(gap_cluster: GapCluster, committee: Committee) -> list[str]:
    """
    Generate questions that would help the system learn about the gap.
    """

    base_question = gap_cluster.recent_examples[0].query_text
    questions = []

    # Strategy 1: Parameterized variations
    if gap_cluster.question_type == "how":
        questions.extend([
            f"How does {entity} handle edge case X?",
            f"How would you change {entity} to support Y?"
        ] for entity in gap_cluster.entities[:2])

    # Strategy 2: Dependency variations
    entity1, relation, entity2 = gap_cluster.missing_entity_relations[0]
    questions.extend([
        f"What is the relationship between {entity1} and {entity2}?",
        f"Why is {entity1} connected to {entity2}?",
        f"How does {entity1} use {entity2}?",
    ])

    # Strategy 3: Committee identifies confusing ones
    high_uncertainty = committee.identify_high_uncertainty_queries(questions)

    # Rank by usefulness
    return sorted(high_uncertainty, key=lambda q: gap_cluster.frequency_per_week)
```

---

## Part 3: Integration with RAG Pipeline

### 3.1 Modify Retriever to Expose Uncertainty

```python
class UncertaintyAwareRetriever:
    """
    Enhanced retriever that signals when confidence is low.
    """

    def __init__(self, base_retriever, embedding_model, threshold: float = 0.6):
        self.base_retriever = base_retriever
        self.embedding_model = embedding_model
        self.confidence_threshold = threshold

    def retrieve(self, query: str, top_k: int = 5) -> tuple[list[Document], float]:
        """
        Returns: (documents, confidence_score)

        confidence_score = how confident is the retriever that these are relevant?
        """

        # Standard retrieval
        docs = self.base_retriever.retrieve(query, top_k)

        # Compute confidence: how central is the query in the embedding space?
        query_embedding = self.embedding_model(query)
        doc_embeddings = [self.embedding_model(d.text) for d in docs]

        # Confidence = mean similarity to top docs
        similarities = [
            cosine_similarity(query_embedding, d_emb)
            for d_emb in doc_embeddings
        ]
        confidence = mean(similarities)

        # Flag low confidence
        if confidence < self.confidence_threshold:
            # Log as abstention event
            self.log_abstention_event(
                query=query,
                confidence=confidence,
                retrieved_docs=docs
            )

        return docs, confidence
```

### 3.2 Modify Generator to Handle Low Confidence

```python
class EpistemicAwareGenerator:
    """
    Enhanced generator that abstains when confident.
    """

    def __init__(self, base_generator, committee: Committee):
        self.base_generator = base_generator
        self.committee = committee
        self.confidence_threshold = 0.7

    def generate(self,
                 query: str,
                 context_docs: list[Document]) -> dict:
        """
        Generate answer, but include metadata about confidence and epistemic status.
        """

        # Generate base answer
        answer = self.base_generator.generate(query, context_docs)

        # Assess confidence (multiple approaches)
        # Approach 1: Self-confidence from model
        self_confidence = self.base_generator.get_confidence_score(query, answer)

        # Approach 2: Committee disagreement
        committee_responses = self.committee.query_all(query)
        committee_disagreement = self.committee.measure_disagreement(committee_responses)

        # Approach 3: Validation against context
        # Does answer actually appear in provided context?
        answer_supported = check_answer_in_docs(answer, context_docs)

        # Combined confidence
        combined_confidence = (self_confidence * 0.4 +
                              (1 - committee_disagreement) * 0.4 +
                              float(answer_supported) * 0.2)

        # Decision: answer vs. abstain + propose
        if combined_confidence < self.confidence_threshold:
            return {
                "type": "abstention_with_proposal",
                "confidence": combined_confidence,
                "tentative_answer": answer,
                "gap_detected": True,
                "gap_analysis": diagnose_gap_from_query(query, context_docs),
                "clarifying_question": generate_clarifying_question(query),
                "suggested_source": find_missing_source(query)
            }
        else:
            return {
                "type": "answer",
                "answer": answer,
                "confidence": combined_confidence,
                "sources": [d.source for d in context_docs]
            }
```

---

## Part 4: Feedback Loop & Learning

### 4.1 Closing Gaps

```python
class GapClosingLoop:
    """
    Track whether proposed gap fixes actually improve performance.
    """

    def __init__(self, gap_tracker: dict[str, GapCluster]):
        self.gap_tracker = gap_tracker
        self.closed_gaps = []

    def apply_proposal(self, proposal: Proposal, action: Action):
        """
        Execute the proposal (e.g., ingest new docs).
        """
        if action.type == "ingest_source":
            # Actually add the source to knowledge base
            docs = load_source(action.source)
            self.knowledge_base.add_documents(docs)

        elif action.type == "enrich_relations":
            # Add relations to code graph
            for entity1, relation, entity2 in action.relations:
                self.code_graph.add_edge(entity1, entity2, label=relation)

        # Mark as "in progress"
        self.gap_tracker[proposal.gap_id].status = "closing"
        self.gap_tracker[proposal.gap_id].applied_proposals.append(action)

    def validate_closure(self, gap_id: str, new_queries: list[str]) -> bool:
        """
        Did the proposed fix actually reduce abstentions?

        Test: Run new_queries through the system.
        Expected: Higher confidence than the original gap cluster.
        """

        original_cluster = self.gap_tracker[gap_id]
        original_confidence = original_cluster.average_confidence  # was ~0.5

        new_confidences = []
        for query in new_queries:
            response = self.system.query(query)
            new_confidences.append(response.confidence)

        improvement = mean(new_confidences) - original_confidence

        if improvement > 0.15:  # 15% confidence boost
            self.gap_tracker[gap_id].status = "closed"
            self.closed_gaps.append(gap_id)
            return True
        else:
            self.gap_tracker[gap_id].status = "partial"
            return False
```

---

## Part 5: User Interaction Patterns

### 5.1 Abstention Response (Instead of Low-Quality Answer)

**Current behavior:**
```
User: "How does the payment system handle currency conversion?"
System: *Low confidence* "The payment system handles currency conversion in
the convert_currency function... probably."
```

**Better behavior (epistemic):**
```
User: "How does the payment system handle currency conversion?"
System:
  I'm not confident about currency conversion details.

  What I found: The payment system has a convert_currency() function,
  but I don't have clear documentation on:
  - Exchange rate sources
  - Decimal precision handling
  - Error cases (network failures, unsupported currencies)

  Help me understand better:
  - Are you asking about the algorithm or the external API?
  - Do you need to modify this code?

  [Suggested sources: /docs/payment-api.md, test_currency_conversion.py]
```

### 5.2 Gap Proposal Response

```
System:
  Based on similar questions from other users, we've identified gaps in:

  TOP GAPS THIS WEEK:
  1. [Error handling in async functions]
     - Frequency: 7 similar questions
     - Recommended action: Add error handling docs
     - Effort: 1-2 hours
     - Would help: ~10 queries

  2. [Database migration strategy]
     - Frequency: 4 similar questions
     - Recommended action: Ingest migration guide
     - Effort: 30 mins
     - Would help: ~5 queries

  Want to close gap #1? I can generate test questions to verify the fix.
```

---

## Part 6: Metrics & Monitoring

### 6.1 Gap Health Dashboard

```python
class GapMetrics:

    def compute_system_epistemic_health(self) -> dict:
        """
        Overall health of the knowledge system.
        """

        return {
            "coverage": {
                "topics_well_covered": len(self.topics_with_low_abstention),
                "topics_with_gaps": len(self.gap_clusters),
                "gap_coverage_ratio": len(self.gap_clusters) / len(self.all_topics)
            },

            "calibration": {
                "avg_confidence": mean([e.confidence for e in self.recent_events]),
                "accuracy_at_high_conf": accuracy_for_confidence_threshold(0.9),
                "accuracy_at_med_conf": accuracy_for_confidence_threshold(0.6),
                "miscalibration_score": compute_miscalibration()
            },

            "gap_closure": {
                "closed_gaps_this_month": len([g for g in self.all_gaps
                                               if g.status == "closed"
                                               and g.closed_date > 30_days_ago]),
                "avg_closure_time": mean([g.closure_time for g in self.closed_gaps]),
                "closure_success_rate": len(self.closed_gaps) / len(self.all_gaps)
            },

            "user_impact": {
                "queries_affected_by_gaps": count_queries_in_gap_clusters(),
                "users_who_encountered_gaps": count_unique_users_with_abstentions(),
                "avg_user_satisfaction_no_gaps": satisfaction_score(query_type="answered"),
                "avg_user_satisfaction_with_gaps": satisfaction_score(query_type="abstained")
            }
        }
```

---

## Part 7: Concrete Example: Python Codebase

### Scenario
A codebase with:
- 50 Python files
- Heavy async/await usage
- Database migrations
- API integrations

### Week 1 Results

**Gap Cluster Detected:**
```
cluster_id: "async_error_handling"
topic: "error handling"
question_type: "how" (56%), "what happens" (32%), "why" (12%)
size: 8 queries
frequency: 8 / 7 days = 1.14 per day
recent_examples:
  - "How should I handle timeout errors in async functions?"
  - "What happens when an async task fails?"
  - "How do we handle cancellation in background tasks?"

diagnosis: EPISTEMIC
- Corpus has async examples but no systematic error handling pattern
- No dedicated error handling docs
- Missing: exception hierarchy, retry logic, cancellation protocol
```

**Proposal Generated:**
```
action: "ingest_source"
source: "async-error-handling.md"
description: "Add systematic guide to error handling in async code"
effort: "2 hours"
estimated_impact: "5-8 queries resolved"
priority: 0.85 / 1.0  (frequency * impact)

clarifying_question: "Are you asking about handling errors within a task,
                      or cancelling entire async operations?"
```

**Applied & Validated:**
```
After ingesting async-error-handling.md:
- New queries on this topic: confidence improved from 0.52 → 0.71
- False positives (hallucinations): 2 → 0
- User satisfaction: 3.2 → 4.5 / 5.0
- Gap status: CLOSED
```

---

## Summary: The System's Epistemic Journey

1. **Early state:** System answers all questions (some hallucinating), no feedback
2. **Instrumented state:** System tracks when it's uncertain, logs abstentions
3. **Diagnostic state:** System clusters abstentions to find patterns
4. **Proposing state:** System generates targeted proposals to close gaps
5. **Learning state:** System validates proposals, adjusts confidence thresholds
6. **Expert state:** System knows what it knows and systematically discovers what it doesn't

The transformation from passive answerer to active epistemic system requires only:
- Confidence tracking (already in most LLMs)
- Clustering of low-confidence events
- Diagnosis of gap types
- Proposal generation
- Feedback loop validation

Everything else follows naturally.

**End of implementation guide.**
