[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/YG8zkJnm)


# ============================================================
# INFOH515 - Big Data Analytics (ULB) - Project 2025-2026
# Docker Compose: Spark + Jupyter + HDFS
# ============================================================
#
# SERVICES:
#   infoh515        → PySpark + Jupyter (your main workspace)
#   hdfs-namenode   → HDFS master node
#   hdfs-datanode   → HDFS storage node
#
# OLLAMA runs natively on Windows (not in Docker).
# Install from: https://ollama.com
# Then run:     ollama pull llama3.2:3b
# From inside the container, reach it via: http://host.docker.internal:11434
#
# USAGE:
#   First build:    docker compose up --build
#   Next launches:  docker compose up
#   Stop:           docker compose down
#   Stop + wipe:    docker compose down -v   (removes HDFS data too!)
#
# PORTS:
#   http://localhost:8888  → Jupyter Notebook
#   http://localhost:4040  → Spark UI
#   http://localhost:9870  → HDFS Web UI (NameNode)
# ============================================================
