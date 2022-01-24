
#### Testing ddl code for guideline #1 c (iv) regarding foreign constraints and deletion of referenced data from the posts table

CREATE TABLE "posts" (
"id"  SERIAL PRIMARY KEY,
"topic_id" INTEGER REFERENCES "topics" ("id") ON DELETE CASCADE,
"user_id" INTEGER REFERENCES Users ("id") ON DELETE SET NULL,
"title" VARCHAR(100) CONSTRAINT title_rules NOT NULL,
    CHECK (LENGTH(TRIM("title")) > 0),
"text_content" TEXT,
"url" VARCHAR,
CONSTRAINT check_URL_content CHECK (("url" IS NULL AND "text_content" IS NOT NULL) OR ("text_content" IS NULL AND "url" IS NOT NULL)));

ALTER TABLE "posts"
ALTER "topic_id" SET NOT NULL;



---- this is to test DML to make sure the "posts" table migrates properly [SUCCESS]

INSERT INTO "posts" ("topic_id", "user_id", "title", "text_content")
  VALUES ('1', '1', 'nicep', 'look');

INSERT INTO "topics" ("topic_name")
     VALUES ('great_project');

select * from topics;

INSERT INTO "users" ("username")
     VALUES ('ternapolis@ws.com');


---at this point posts should be populated with above values

TRUNCATE TABLE topics CASCADE;

select * from posts;

---should be empty
