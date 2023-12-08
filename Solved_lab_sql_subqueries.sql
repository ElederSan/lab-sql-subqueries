USE sakila;

/*
1.Determine the number of copies of the film "Hunchback Impossible" that exist in the inventory system.
2.List all films whose length is longer than the average length of all the films in the Sakila database.
3.Use a subquery to display all actors who appear in the film "Alone Trip".

Bonus:

4.Sales have been lagging among young families, and you want to target family movies for a promotion. Identify all movies categorized as family films.
5.Retrieve the name and email of customers from Canada using both subqueries and joins. To use joins, you will need to identify the relevant tables and their primary and foreign keys.
6.Determine which films were starred by the most prolific actor in the Sakila database. A prolific actor is defined as the actor who has acted in the most number of films. First, you will need to find the most prolific actor and then use that actor_id to find the different films that he or she starred in.
7.Find the films rented by the most profitable customer in the Sakila database. You can use the customer and payment tables to find the most profitable customer, i.e., the customer who has made the largest sum of payments.
8.Retrieve the client_id and the total_amount_spent of those clients who spent more than the average of the total_amount spent by each client. You can use subqueries to accomplish this.

*/
-- 1.Determine the number of copies of the film "Hunchback Impossible" that exist in the inventory system.

-- I first retrieve the film_id for "Hunchback Impossible" from the film table and then count the distinct inventory_id from the table inventory when the film_id is 439 -> "Hunchback Impossible"
-- I know it could have been done without a subquery, but taking into account that the lab is about subqueries, I have used the chance to practice.


SELECT distinct(count(inventory_id)) AS number_copies FROM sakila.inventory
WHERE film_id = (
SELECT i.film_id FROM sakila.inventory i
LEFT JOIN sakila.film f
ON i.film_id=f.film_id
WHERE f.title ="Hunchback Impossible"
LIMIT 1);



-- 2.List all films whose length is longer than the average length of all the films in the Sakila database.

-- I fetch the avg lengh first and then filter the film table selecting only the rows with a > length as the avg of 115.2720. 
-- Same here, could have been done without subqueries.

SELECT film_id, title,length, round(avg(length) OVER(),2) AS "avg_movie_lenght" FROM sakila.film
WHERE length >(SELECT avg(length) FROM sakila.film)
ORDER BY length DESC;


SELECT avg(length) FROM sakila.film;

-- 3.Use a subquery to display all actors who appear in the film "Alone Trip".
-- I create a left join between the film_actor and actor tables to be able to get the names from the actors
-- I get the film_id from the film table, applying a string filter on the title column. 
-- I select the actor names from the joint table, fetching the film_id from the previous subquery

SELECT * FROM sakila.actor;

SELECT fa.actor_id,fa.film_id AS film_id_alone_trip, a.first_name,a.last_name FROM film_actor fa
LEFT JOIN sakila.actor a
ON fa.actor_id=a.actor_id
WHERE fa.film_id =(SELECT film_id FROM sakila.film
WHERE title="Alone Trip");



-- 4.Sales have been lagging among young families, and you want to target family movies for a promotion. Identify all movies categorized as family films.

-- I get the category_id from "family" movies by filtering the name of the category on the category table
-- I join the film and film_category table with a left join to get the  titles from the movies and fecth the category_id from the previous subquery. 

SELECT fc.film_id AS film_id, f.title AS movie_title FROM sakila.film_category fc
LEFT JOIN sakila.film f
ON fc.film_id = f.film_id
WHERE fc.category_id = (
SELECT category_id FROM sakila.category
WHERE name = "family");

-- 5.Retrieve the name and email of customers from Canada using both subqueries and joins. To use joins, you will need to identify the relevant tables and their primary and foreign keys.

-- I get the country_id from the country table by filtering the name of the country "Canada".
-- I get the city_id in Canada from the city table, filtering the cities with the country_id obtained from the previous subquery.
-- I get the address_id from the address table, by picking city_id from cities in Canada from the previous subquery
-- I get the first name and last name from the table customer by selecting address_id from the previous subquery, which contains cities located in Canada. 

SELECT first_name,last_name FROM sakila.customer
WHERE address_id IN(
SELECT address_id FROM sakila.address
WHERE city_id IN(
SELECT city_id FROM sakila.city
WHERE country_id = 
(SELECT country_id FROM sakila.country
WHERE country = "Canada")
)
);



-- 6.Determine which films were starred by the most prolific actor in the Sakila database. A prolific actor is defined as the actor who has acted in the most number of films. First, you will need to find the most prolific actor and then use that actor_id to find the different films that he or she starred in.

-- I get the most prolifict actor creating by computing the distinct count of film_id per actor, using a groupby, I sort it in descending order by film_count and select the top value.
-- I select the first,last name and actor id, by picking the actor_id obtained with the previous subquery

SELECT first_name, last_name, actor_id FROM sakila.actor
WHERE actor_id = (SELECT actor_id FROM (
        SELECT actor_id, COUNT(DISTINCT film_id) AS film_count
        FROM sakila.film_actor
        GROUP BY actor_id
        ORDER BY film_count DESC
        LIMIT 1
    ) AS sub1
);

-- 7.Find the films rented by the most profitable customer in the Sakila database. You can use the customer and payment tables to find the most profitable customer, i.e., the customer who has made the largest sum of payments.

-- I calculate the most profitable customer by summing the rental amount per customer, using a groupy by and sorting the results by the sum_payments in descending order. I then pic the top record.
-- I get the inventory_id from the inventory table, filtering customer_id obtained with the previous subquery
-- I select the titles rented by the most profitable customer by filtering the film_id from the previous subquery with the inventory_id

SELECT title FROM sakila.film
WHERE film_id IN (SELECT film_id 
FROM(
SELECT film_id FROM sakila.inventory
WHERE inventory_id IN (SELECT inventory_id 
FROM (
SELECT inventory_id FROM sakila.rental
WHERE customer_id = (SELECT customer_id FROM (
SELECT customer_id, sum(amount) AS sum_payments 
FROM sakila.payment
GROUP BY customer_id
ORDER BY sum_payments DESC 
LIMIT 1
) AS sub1
)
) AS sub2
)
) AS sub3
);


-- 8.Retrieve the client_id and the total_amount_spent of those clients who spent more than the average of the total_amount spent by each client. You can use subqueries to accomplish this.

-- I calculate the avg per rental
-- I get the customer_id of those customers with a higher avg per rental obtained from the previous subquery
-- I get the customer_id and calculate the total amount spent (sum) by the customers filtered with the previous subquery.

SELECT customer_id, sum(amount) AS total_amount_spent FROM sakila.payment
GROUP BY customer_id
HAVING customer_id IN (
SELECT customer_id FROM(
SELECT customer_id, AVG(amount) AS average_amount_spent FROM sakila.payment
GROUP BY customer_id
HAVING average_amount_spent > (SELECT avg_amount_spent
FROM(SELECT round(AVG(amount),2) AS avg_amount_spent FROM sakila.payment
) AS sub1
)
) AS sub2
); 
