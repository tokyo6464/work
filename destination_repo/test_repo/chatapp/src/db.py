from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# データベースのURL、パスワードとホストは環境に合わせて設定
SQLALCHEMY_DATABASE_URL = (
    "mysql+pymysql://chatuser:your_password@localhost/chatapp"
)

engine = create_engine(SQLALCHEMY_DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
