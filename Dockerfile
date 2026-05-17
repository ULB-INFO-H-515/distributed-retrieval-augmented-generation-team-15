# ============================================================
# INFOH515 - Jupyter + librairies projet
# Base: image officielle pyspark-notebook (Spark + Hadoop inclus)
# On ajoute uniquement les librairies manquantes pour le projet
# ============================================================

FROM jupyter/pyspark-notebook:spark-3.3.2

# Librairies projet
RUN pip install --no-cache-dir \
    # Task 1 - PDF ingestion
    pypdf \
    # Task 1 - Embeddings
    sentence-transformers \
    gensim \
    scikit-learn \
    # Task 1 - Parquet / stockage
    pyarrow \
    fastparquet \
    # Task 2 - LLM (Ollama sur Windows)
    ollama \
    requests \
    # Task 3 - Recherche approchée (LSH/HNSW, Option 4)
    faiss-cpu \
    # Task 2 - Métriques de distance
    scipy \
    # Task 3 - Graphiques d'évaluation
    matplotlib \
    # Task 3 - Métriques système
    psutil \
    # Task 3 - Qualité de génération
    rouge-score \
    nltk \
    # Kafka (TPs)
    kafka-python \
    # Utilitaires
    tqdm