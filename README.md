[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/YG8zkJnm)

# RAG Pipeline — INFO-H515 Big Data Project

This project implements a full **Retrieval-Augmented Generation (RAG)** pipeline on top of course material PDFs. Given a natural language query, the system retrieves the most relevant text passages using Apache Spark and generates exam questions grounded in those sources using a local LLM (Ollama).

The project is split across two notebooks that must be run in order.

---

## Project structure

- notebook_1.ipynb              # Task 1 : ingestion, preprocessing and embeddings
- Notebook_2_retrieval.ipynb    # Task 2 & 3 : retrieval, generation and evaluation
- course_material/              # Folder containing the source PDF files (not included)
- README.md

---

## Environment setup

The project runs inside the Docker environment provided by the course repository.


### Ollama setup

The generation step calls a local LLM through Ollama. Make sure Ollama is running on your host machine and that the model is downloaded before running notebook 2.

```bash
ollama pull llama3.2:3b
```

The notebooks communicate with Ollama at `http://host.docker.internal:11434`, which is the standard address to reach the host from inside a Docker container on Mac and Windows. On Linux you may need to replace this with your host machine's IP address.

---

## Notebook 1 — Ingestion, preprocessing and embeddings

**File :** `notebook_1.ipynb`

This notebook reads all PDF files in the course material folder, extracts and cleans the text, splits it into overlapping chunks, and produces embedding vectors for each chunk. The results are saved as Parquet files that notebook 2 reads directly.

### Pipeline steps

1. **Configuration** — all parameters are centralised in a single `RAGConfig` dataclass. Change the embedding strategy or chunk size here and it propagates everywhere.

2. **Spark initialisation** — a local Spark session is created to process PDFs in parallel across CPU cores.

3. **PDF ingestion** — all PDF files in `input_dir` are listed and distributed as an RDD. Each element is a path to one PDF.

4. **Page-by-page text extraction** — `pypdf` opens each PDF and extracts text one page at a time. The RDD is flattened so each element is one page.

5. **Text cleaning** — four cleaning steps fix the artefacts introduced by pypdf : re-joining hyphenated words, replacing line breaks with spaces, collapsing multiple spaces, and stripping leading/trailing whitespace.

6. **Chunking** — each page is split into overlapping rolling windows of words. The overlap ensures that concepts that span a page boundary are not lost.

7. **Embedding** — chunks are vectorised using one of three strategies (set via `cfg.embedding_strategy`) :
   - `sbert` — sentence-level embeddings (384 dimensions, dense, context-aware)
   - `tfidf` — sparse TF-IDF vectors trained on the corpus with Spark MLlib
   - `word2vec` — dense vectors from Spark Word2Vec, averaged per chunk

8. **Parquet export** — the final DataFrame (chunks + embeddings) is saved to `output_dir`. For TF-IDF and Word2Vec, the fitted models are also saved so notebook 2 can vectorise queries with the exact same transformation.

### Configuration reference

| Parameter | Default | Description |
|---|---|---|
| `input_dir` | `course_material` | Folder containing the source PDFs |
| `output_dir` | `/home/guest/shared/course_material` | Where Parquet files and models are saved |
| `parallelism` | `4` | Number of Spark partitions |
| `chunk_size_words` | `200` | Words per chunk |
| `chunk_overlap_words` | `50` | Overlap between consecutive chunks |
| `embedding_strategy` | `sbert` | One of `sbert`, `tfidf`, `word2vec` |

### Output schema

Each row in the saved Parquet file contains :

| Column | Type | Description |
|---|---|---|
| `id` | Long | Unique chunk identifier |
| `source_pdf` | String | Name of the source PDF |
| `page_num` | Integer | Page number within the PDF |
| `chunk_id` | String | Unique string identifier for the chunk |
| `start_word` | Integer | Start word index within the page |
| `end_word` | Integer | End word index within the page |
| `chunk_text` | String | Raw text of the chunk |
| `embedding` | Array[Float] | Embedding vector |
| `embedding_strategy` | String | Strategy used to produce the embedding |

---

## Notebook 2 — Retrieval, generation and evaluation

**File :** `Notebook_2_retrieval.ipynb`

This notebook loads the Parquet files produced by notebook 1, retrieves the most relevant chunks for a given query using Spark UDFs, generates exam questions with a local LLM, and evaluates the full pipeline.

### Task 2 — Retrieval and generation

**Retrieval** — the query is vectorised with the same strategy used in notebook 1. A Spark UDF applies the chosen similarity metric across the entire corpus and returns the top-k chunks.

Two similarity metrics are available :
- `cosine` — dot product divided by the product of norms, higher is better
- `euclidean` — L2 distance, lower is better

The UDFs run directly on Spark workers, avoiding the cost of `.collect()` on the full corpus.

**Generation** — the top-k chunks are formatted as numbered sources and injected into a strict prompt. The prompt instructs the LLM to generate exam questions using only the provided sources, with citations for every question and answer. The LLM is called via the Ollama REST API.

### Task 3 — Evaluation

The evaluation is built around a manually constructed gold set of 8 course-related queries, each annotated with the expected relevant pages and expected answer keywords.

**Retrieval metrics**
- `precision@k` — fraction of the k retrieved chunks that come from a gold page
- `recall@k` — fraction of gold pages covered by the retrieval

**Generation metrics**
- `grounding_score` — fraction of expected keywords found in the generated answer
- `elements_coverage` — detailed version of grounding, returns found and missing elements
- `citation_accuracy` — fraction of LLM citations that can be traced back to a retrieved source

**Format adherence** — checks that the LLM output is valid JSON with all required fields (`query`, `questions`, `refusal`) and that citations follow a recognisable format.

**System metrics** — latency (retrieval vs generation), token counts, throughput and memory delta are collected for every query.

**Regression testing** — after a satisfying run, scores are saved as a baseline. Any subsequent run is automatically compared against it to flag metric drops above a 5-point threshold. No extra pipeline runs are needed : the scores from the current evaluation are reused directly.

**Manual evaluation** — a scoring grid (0–2) across six criteria (relevance, correctness, faithfulness, citation support, clarity, format adherence) is printed for the first five results to allow human review of question quality.

### Key parameters (set at the top of notebook 2)

| Parameter | Default | Description |
|---|---|---|
| `embedding_strategy` | `sbert` | Must match the strategy used in notebook 1 |
| `similarity_strategy` | `cosine` | `cosine` or `euclidean` |
| `number_of_text_chunks_to_retrieve` | `4` | Number of chunks passed to the LLM |
| `number_of_questions_to_generate` | `2` | Questions per query |
| `generator_model` | `llama3.2:3b` | Ollama model name |
| `max_context_tokens` | `2048` | Max tokens sent to the LLM |

---

## Running order

1. Place your PDF files in the `course_material/` folder.
2. Start the Docker environment (see setup here) .
3. Make sure Ollama is running on your host with `llama3.2:3b` pulled.
4. Run `notebook_1.ipynb` once for each embedding strategy you want to test (`sbert`, `tfidf`, `word2vec`).
5. Run `Notebook_2_retrieval.ipynb` — make sure `embedding_strategy` at the top matches the one used in step 4.

> **Note :** notebook 2 reads the Parquet files and model files saved by notebook 1. If the embedding strategy in notebook 2 does not match, the retrieval will fail with a file not found error.
>>>>>>> 228644c (add README and remove unused files and folders)
