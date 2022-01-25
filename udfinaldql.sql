### Guideline #2: here is a list of queries that Udiddit needs in order to support its website and administrative interface.
Note that you don’t need to produce the DQL for those queries: they are only provided to guide the design of your new database schema. /*

a.  List all users who haven’t logged in in the last year. */

SELECT id
FROM users
WHERE EXTRACT(YEAR FROM “last_login”) != 2021;
/*

b.  List all users who haven’t created any post. */

select * from users
where id NOT IN (select user_id from posts);
/*

c.  Find a user by their username.

SEE indexes

d.  List all topics that don’t have any posts.

SEE indexes

e.  Find a topic by its name.

SEE indexes

f.  List the latest 20 posts for a given topic.

SEE indexes

g.  List the latest 20 posts made by a given user. */

SELECT *
FROM posts
ORDER BY timestamp DESC
LIMIT 20;

/*
h.  Find all posts that link to a specific URL, for moderation purposes.

SEE indexes

i.  List all the top-level comments (those that don’t have a parent comment) for a given post. */

SELECT *
FROM comments
WHERE parent_id is NULL;
/*
j.  List all the direct children of a parent comment.

You can create index on parent_id to execute the query

i.e. select all comments whose parent_id is 4. This will list all the direct child comments.*/

SELECT *
FROM comments
Where parent_id = 4
/*
k.  List the latest 20 comments made by a given user. */

SELECT id
FROM comments
WHERE user_id = n
ORDER BY time
LIMIT 20
/*
l.  Compute the score of a post, defined as the difference between the number of upvotes and the number of downvotes */

SELECT post_id, SUM(vote)
FROM votes
GROUP BY post_id;
