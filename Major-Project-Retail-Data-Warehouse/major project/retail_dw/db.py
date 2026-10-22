"""Database connection (PostgreSQL) shared by ETL, API and tests."""
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()
DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql+psycopg2://postgres:postgres@localhost:5432/retail_dw"
)
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
