--ROLLBACK;

DROP TABLE IF EXISTS machines_owners;
DROP TABLE IF EXISTS groups_customers;
DROP TABLE IF EXISTS groups;
DROP TABLE IF EXISTS machines;
--DROP FUNCTION IF EXISTS emp_stamp;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    balance INTEGER NOT NULL,
    CONSTRAINT email_not_empty CHECK (email <> ''),
    CONSTRAINT balance_not_negative CHECK (balance >= 0)
);

CREATE TABLE machines (
    id SERIAL PRIMARY KEY,
    make TEXT NOT NULL,
    price INTEGER,
    CONSTRAINT make_not_empty CHECK (make <> ''),
    CONSTRAINT price_not_negative CHECK (price > 0)
);

CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    minimum_limit INTEGER,
    balance INTEGER,
    CONSTRAINT name_not_empty CHECK (name <> ''),
    CONSTRAINT limit_not_negative CHECK (minimum_limit >= 0),
    CONSTRAINT balance_not_negative CHECK (balance >= 0)
);

CREATE TABLE groups_customers (
    group_id SERIAL NOT NULL,
    customer_id SERIAL NOT NULL,
    PRIMARY KEY (group_id, customer_id),
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE machines_owners (
    machine_id SERIAL UNIQUE NOT NULL,
    group_id SERIAL,
    customer_id SERIAL,
    FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

/* alternative way
CREATE FUNCTION emp_stamp() RETURNS trigger AS $emp_stamp$
    BEGIN
        IF NEW.name LIKE 'csoport' THEN
            RAISE EXCEPTION 'works!';
        END IF;
        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER emp_stamp BEFORE INSERT OR UPDATE ON groups
    FOR EACH ROW EXECUTE PROCEDURE emp_stamp();
*/

/*Add new customer*/
BEGIN;
INSERT INTO customers (email, balance) VALUES
    ('user0@user0.com', 0),
    ('user00@user00.com', 0),
    ('user1@user1.com', 1000),
    ('user2@user2.com', 2500),
    ('user3@user3.com', 4000);
COMMIT;

/*List customers*/
BEGIN;
SELECT email FROM customers;
COMMIT;

/*Customer details*/
BEGIN;
SELECT id, email, balance FROM customers WHERE email = 'user0@user0.com';
COMMIT;

/*Delete existing customer*/
BEGIN;
DELETE FROM customers WHERE email = 'user3@user3.com';
COMMIT;

/*List customers with no remaining balance*/
BEGIN;
SELECT id, email, balance FROM customers WHERE balance = 0;
COMMIT;

/*Add new machine*/
BEGIN;
INSERT INTO machines (make, price) VALUES
    ('traktor1', 800),
    ('traktor2', 500),
	('traktor3', 700),
    ('traktor4', 900);
COMMIT;

/*List machines*/
BEGIN;
SELECT make, price FROM machines;
COMMIT;

/*List machines between a price range*/
BEGIN;
SELECT make, price FROM machines WHERE price < 900 AND price > 400;
COMMIT;

/*Delete existing machine*/
BEGIN;
DELETE FROM machines WHERE make = 'traktor4';
COMMIT;

/*Add new group*/
BEGIN;
INSERT INTO groups (name, minimum_limit, balance) VALUES
	('group1', 10, 1500),
	('group2', 20, 1000),
	('group3', 1, 2000),
	('group4', 15, 0);
COMMIT;

/*List groups*/
BEGIN;
SELECT name, minimum_limit FROM groups;
COMMIT;

/*Group details*/
BEGIN;
SELECT name, minimum_limit, balance FROM groups WHERE name = 'group3';
COMMIT;

/*Delete existing group*/
BEGIN;
DELETE FROM groups WHERE name = 'group4';
COMMIT;

/*groupJoin*/
BEGIN;
INSERT INTO groups_customers (group_id, customer_id) VALUES
	(1, 3),
    (1, 4);
UPDATE customers SET balance = balance - 50 WHERE id = 4;
COMMIT;

/*Display membership data*/
BEGIN;
SELECT email FROM customers WHERE id IN(SELECT customer_id FROM groups_customers WHERE group_id = 1);
COMMIT;

/*Purchase machine*/
BEGIN;
INSERT INTO machines_owners (machine_id, customer_id) VALUES
    (2, 3);
UPDATE customers SET balance = balance - (SELECT price FROM machines WHERE id = 2) WHERE id = 3;
INSERT INTO machines_owners (machine_id, group_id) VALUES
	(3, 2);
UPDATE groups SET balance = balance - (SELECT price FROM machines WHERE id = 3) WHERE id = 2;
COMMIT;

/*Purchase history*/
BEGIN;
SELECT COUNT(machine_id) FROM machines_owners WHERE customer_id = 3;
COMMIT;

/*Machine availability*/
BEGIN;
SELECT make FROM machines WHERE id NOT IN (SELECT machine_id FROM machines_owners);
COMMIT;