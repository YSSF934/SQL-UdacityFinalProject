\d, \dt, \d+

a.
CREATE TABLE "users" (
"id" SERIAL PRIMARY KEY,
"username" VARCHAR(25) UNIQUE NOT NULL,
     CONSTRAINT chkUserName CHECK (LENGTH(TRIM("username")) > 0),
"last_login" TIMESTAMP
);


b.
CREATE TABLE "topics" (
"id"  SERIAL PRIMARY KEY,
"topic_name" VARCHAR(30) UNIQUE NOT NULL,
"description" VARCHAR (500));

--ALTER TABLE "users" ADD PRIMARY KEY ("id");

c.
CREATE TABLE "posts" (
"id"  SERIAL PRIMARY KEY,
"topic_id" INTEGER REFERENCES "topics" ("id") ON DELETE CASCADE,
"user_id" INTEGER REFERENCES Users ("id") ON DELETE SET NULL,
"title" VARCHAR(100) CONSTRAINT title_rules NOT NULL,
    CHECK (LENGTH(TRIM("title")) > 0),
"text_content" TEXT,
"url" VARCHAR,
CONSTRAINT check_URL_content CHECK (("url" IS NULL AND "text_content" IS NOT NULL) OR ("text_content" IS NULL AND "url" IS NOT NULL)));

---use this one to not null the topic_id column
ALTER TABLE "posts"
ALTER "topic_id" SET NOT NULL;

---the below is trying to add two contraints.  key error
ALTER TABLE "posts"
ADD CONSTRAINT "valid_topic"
FOREIGN KEY ("topic_id") REFERENCES "topics" ("id") NOT NULL;


Therefore, the point here is to evaluate your entire schema and determine which foreign key columns need to prevent NULL inputs, and then add the necessary constraints accordingly.

it means that columns, user_id and post_id, are NOT NULL unless they are specifically set to be NULL. Please, and with the help of resources, explain why my understanding is wrong.

d.
CREATE TABLE "comments" (
"id" BIGSERIAL PRIMARY KEY,
"text_content" TEXT NOT NULL
CONSTRAINT not_empty CHECK(LENGTH(TRIM("text_content")) > 0),
"post_id" BIGINT REFERENCES "posts" ("id") ON DELETE CASCADE,
"user_id"  BIGINT REFERENCES "users" ("id") ON DELETE SET NULL,
"parent_id" BIGINT REFERENCES "comments" ("id") ON DELETE CASCADE,
"time" TIMESTAMP
);



ALTER TABLE "comments"
ALTER "post_id" SET NOT NULL;


ALTER TABLE "comments"
ALTER "parent_id" SET NOT NULL;

e.

CREATE TABLE "votes" (
"id" SERIAL PRIMARY KEY,
"user_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL,
"post_id" INTEGER REFERENCES "posts" ("id") ON DELETE CASCADE,
"vote" INTEGER CHECK ("vote" = 1 or "vote" = -1)
);


ALTER TABLE "votes"
ADD CONSTRAINT "up_down_vote" CHECK ("vote" = 1 OR "vote" = -1);

ALTER TABLE "votes"
ADD CONSTRAINT "one_vote" UNIQUE ("user_id", "post_id");

----the below is what the NOt NULL constraint does
ALTER TABLE "votes"
ADD CONSTRAINT "validvot_post"
FOREIGN KEY ("post_id") REFERENCES "posts" ("id") NOT NULL;

---use this one
ALTER TABLE "votes"
ALTER ("post_id") SET NOT NULL;

---alternate method "votes" TABLE
---For applying a check on the votes table that each user vote only once on a post, you can apply a UNIQUE constraint on the fields - ("vote_id","user_id","post_id").

--There can be a possibility in the future that a user is deleted and it will become null here. In that situation, the unique constraint will break down, but if the **id** field is there, it will not break.



2.  INDEX notes
---Yes you are right, PRIMARY KEY/UNIQUE KEY Constraints need not to have any additional indexes. You can create INDEX for multiple columns ex: userid,username etc. It is upto the individual developers to take the decision. Your approach for creating INDEX for last_login and username is perfect. You can refer Multip Column Index for more information.


CREATE INDEX "last_login" ON "users" ("last_login"); --2a

List all users who haven’t logged in in the last year.

--eg..SELECT “id” FROM “users” WHERE EXTRACT(YEAR FROM “last_login”) != 2021;


CREATE INDEX "username_index" ON "users" ("username" VARCHAR_PATTERN_OPS); --2c



CREATE INDEX "topics_index" ON "topics" ("topic_name" VARCHAR_PATTERN_OPS); --2e


CREATE INDEX "latest_posts_for_user" ON "posts" ("topic_id", "user_id"); --2f,g

---alteranate method (below) will require "post_date" column

CREATE INDEX "find_latest_post_by_topic" ON "posts" ("topic_id", "post_date"); --2f
CREATE INDEX "find_latest_post_by_user" ON "posts" ("user_id", "post_date"); --2g


CREATE INDEX "find_url" ON "posts" ("url" VARCHAR_PATTERN_OPS); --2h


CREATE INDEX "top_level_comments" ON "comments" ("parent_id");-- 2i,j

---Query: i:

---List all the top level comments(those that don't have a parent comment) for a given post:

select * from comments where parent_id is NULL;

---Query: j:

---List all the direct children of a parent comment

Again, you can create index on parent_id to execute the query

i.e. select all comments whose parent_id is 4. This will list all the direct child comments.

select * from comments
Where "parent_id" = 4


2K.

CREATE INDEX "latest_comments_of_user" ON "comments"("user_id", "time");--2k

---Query: k:

SELECT id
FROM comments
WHERE user_id = n
ORDER BY time
LIMIT 20

2l.

CREATE INDEX "for_vote_score" ON "votes"("post_id", "vote");
---Then, this means that we'll need to create our index for the down_up_vote column, which stores the votes of a post, and the post_id column which will determine which post is referred to, so that anytime we want to compute the score of a post, [total 1s] - [total -1s], for a particular post(post_id value), the query may run in an optimised manner.


--To find the aggregate the sum of votes for a particular post based on post_id, you can directly apply GROUP BY in the votes table on POST_ID and find sum of the VOTE column.




PART III


a.
INSERT INTO "topics" ("topic_name")
SELECT DISTINCT "topic"
FROM "bad_posts";


---the below query is basically the same as above except u.id was pulled from users table. no need because we have serial column for the topics table
INSERT INTO "topics"("id", "topic_name")
SELECT DISTINCT "u"."id", "bp"."topic"
FROM "users" u
JOIN "bad_posts" bp
ON "u"."username" = "bp"."username"
ON CONFLICT ("topics")
DO NOTHING;



b.
INSERT INTO "comments" ("text_content")
SELECT "text_content"
FROM "bad_comments";


INSERT INTO "comments" ("id","user_id","post_id","text_content","parent_id")
SELECT bp.id, u.user_id,bc.post_id,bc.text_content,bc.id
FROM bad_comments bc
JOIN users u
ON bc.username=u.name
JOIN bad_posts bp
ON bp.id=bc.post_id;



c.

INSERT INTO "votes" (
"user_id",
"post_id",
"vote"
)
SELECT u.id,
t1.post_id,
1 AS upvote
FROM
(SELECT id AS post_id,
 Regexp_split_to_table(upvotes, ',') AS upvote_users
FROM bad_posts) t1
JOIN users u
ON u.username = t1.upvote_users

UNION

SELECT u.id,
t1.post_id,
- 1 AS downvote
FROM (
SELECT id AS post_id,
Regexp_split_to_table(downvotes, ',') AS downvote_users
FROM bad_posts) t1
JOIN users u
ON u.username = t1.downvote_users;


---alternate
INSERT INTO "votes" ("post_id", "user_id", "vote")
SELECT t1.id, users.id, 1 AS upvote
FROM (SELECT id, regexp_split_to_table(upvotes, ',') AS downvote_users FROM bad_posts) t1
JOIN users ON users.username = t1.upvote_users;

--or

INSERT INTO votes (user_id,post_id,vote)
SELECT u.id,vote.post_id,1 AS vote
FROM (SELECT id AS post_id,Regexp_split_to_table(upvotes, ',') AS likes
FROM bad_posts) AS vote
JOIN users u ON u.username = vote.likes

UNION

SELECT u.id,vote.post_id,- 1 AS vote
FROM (SELECT id AS post_id,Regexp_split_to_table(downvotes, ',') AS dislikes
FROM bad_posts) AS vote
JOIN users u ON u.username = vote.dislikes;

d.

INSERT INTO "users" ("username")
SELECT t1
FROM
(
  SELECT DISTINCT LEFT("bp"."username",24)
  FROM "bad_posts" bp
UNION
  SELECT DISTINCT  LEFT("bc"."username",24)
  FROM "bad_comments" bc
UNION
  SELECT DISTINCT REGEXP_SPLIT_TO_TABLE("upvotes", ',') AS upvote_users
  FROM "bad_posts"
UNION
  SELECT DISTINCT REGEXP_SPLIT_TO_TABLE("downvotes", ',') AS downvote_users
  FROM "bad_posts") t1
  ON CONFLICT ("username")
DO NOTHING;


INSERT INTO "users" ("username")
SELECT DISTINCT "bp"."username"
FROM "bad_posts" bp

UNION

SELECT DISTINCT "bc"."username"
FROM "bad_comments" bc

UNION

SELECT DISTINCT REGEXP_SPLIT_TO_TABLE("upvotes", ',') AS upvote_users
FROM "bad_posts"

UNION

SELECT DISTINCT REGEXP_SPLIT_TO_TABLE("downvotes", ',') AS downvote_users
FROM "bad_posts";






e.
INSERT INTO posts (id, topic_id, user_id, title,url,text_content)
SELECT b.id,b.topic,b.title,b.url,b.text_content
FROM bad_posts b
JOIN users u
ON b.username = u.username;


INSERT INTO posts (id, topic_id, user_id, title,url,text_content)
SELECT LEFT(bp."title", 100), bp."text_content", bp."url", u."id", t."id"
FROM "bad_posts" bp
JOIN "users" u
ON bp."username" = u."username"
JOIN "topics" t
ON bp."topic" = t."topic_name";

---this works for posts
INSERT INTO "posts" ("title", "text_content", "url", "user_id", "topic_id")
SELECT LEFT(bp."title", 100), bp."text_content", bp."url", u."id", t."id"
FROM "bad_posts" bp
JOIN "users" u
ON bp."username" = u."username"
JOIN "topics" t
ON "topic" = t."topic_name";


there was a foreign key constraint on the posts table so i truncated all the tables so that the data can be inserted in the correct order so that constraints are not violated.

To resolve this, you need to ensure that data is migrated in the right order:
Users -> Topics -> Posts -> Votes
-> Comments
So, users,
topics migrated first,

then
posts, then
votes and comments

---need to migrate possts - comments tomorow
