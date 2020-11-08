from typing import Optional
import asyncpg
import os

pg_url = os.getenv('DATABASE_URL')


async def _create_pool():
    pool: Optional[asyncpg.pool.Pool] = await asyncpg.create_pool(pg_url)

    await pool.execute('''
        CREATE TABLE IF NOT EXISTS queue(
            id serial PRIMARY KEY,
            chat_id bigint,
            payload text,
            created_at timestamp DEFAULT now(),
            retry_at timestamp DEFAULT now(),
            status int DEFAULT 0
        )
    ''')

    return pool


class Database:
    def __init__(self):
        self._pool = None

    @property
    async def postgres(self) -> Optional[asyncpg.pool.Pool]:
        if self._pool is None:
            self._pool = await _create_pool()
        return self._pool

    async def updateAttendance(self, class_id, user_id):
        async with (await self.postgres).acquire(timeout=10) as conn:
            return await conn.execute('''
                INSERT INTO attendances (class_id, user_id)
                VALUES ($1, $2)
                ON CONFLICT (class_id, user_id)
                DO UPDATE SET last_seen_at = now(), hits = attendances.hits + 1;
            ''', class_id, user_id)

    async def updateUser(self, user_id, name, email):
        async with (await self.postgres).acquire(timeout=10) as conn:
            return await conn.execute('''
                INSERT INTO users (id, name, email)
                VALUES ($1, $2, $3)
                ON CONFLICT (id)
                DO UPDATE SET name = $2, email = $3;
            ''', user_id, name, email)


db = Database()
