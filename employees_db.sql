/*
Employees database exploration

Tools Used: Basic Querying, Aggregate functions, Joins, Subquery, Stored routines, Triggers, CASE statement

*/


-- SELECT.....FROM.....STATEMENTS:
	
    -- return all the job titles from titles table
	SELECT DISTINCT title
	FROM titles;


	-- return the number of male and female employees within the company
	SELECT gender, 
		   COUNT(emp_no) AS total_employees
	FROM employees
	GROUP BY gender;


	-- find all employees' first name, last name and gender with same name and different employee no from employees table
	SELECT gender, 
		   first_name, 
		   last_name, 
		   COUNT(emp_no)
	FROM employees
	GROUP BY gender, first_name, last_name
	HAVING COUNT(emp_no) > 1;


-- JOINs AND UNIONs:

	-- Extract a list containing information about all managers' employee number, first and last name, department number, and hire date.
	SELECT 
		dm.emp_no AS manager_emp_no,
		first_name,
		last_name,
		dept_no,
		hire_date
	FROM employees e 
	JOIN dept_manager dm ON e.emp_no = dm.emp_no
	ORDER BY dm.emp_no;
    
    
	-- average male and female salary for each department: 
	SELECT d.dept_name, e.gender, AVG(s.salary)
	FROM employees e 
			JOIN 
		 salaries s ON e.emp_no = s.emp_no
			JOIN 
		 dept_emp de ON e.emp_no = de.emp_no 
			JOIN 
		 departments d ON de.dept_no = d.dept_no
	GROUP BY d.dept_name, e.gender;
		
	/*
	Exercise: Assign emp_no 22 as manager to emp_no from 1-20 and emp_no 39 as manager to 21-40. Return the output as a single table. 
	*/
	SELECT *
	FROM (SELECT emp_no AS employee_ID,
		   MIN(dept_no) AS dept_code,
		   (SELECT emp_no FROM dept_manager dm
		   WHERE emp_no = 110022) AS manager_ID
		   FROM dept_emp de  
		   WHERE emp_no <= 10020
		   GROUP BY emp_no) AS a             -- manager_ID is a subquery which returns a single value
	UNION
	SELECT *
	FROM (SELECT emp_no AS employee_ID,
		  MIN(dept_no) AS dept_code,
		  (SELECT emp_no FROM dept_manager dm
		   WHERE emp_no = 110039) AS manager_ID
		   FROM dept_emp de  
		   WHERE emp_no > 10020 AND emp_no <= 10040
		   GROUP BY emp_no) AS b;            -- a & b here are derived tables, created by a subquery in FROM clause of a SELECT stmt. hence we are aliasing them. 



-- SUBQUERY:	

	-- get all managers' full name with employee number using a Subquery
	SELECT emp_no as manager_emp_no,
		   first_name, 
		   last_name
	FROM employees
	WHERE emp_no IN(SELECT emp_no 
					FROM dept_manager); -- duplicate values(emp no 111534 in dept manager) are not present in the output
					

	-- return full name of all department managers within the company using a Subquery
	SELECT first_name, 
		   last_name
	FROM employees e
	WHERE EXISTS(SELECT *
				  FROM dept_manager dm
				  WHERE dm.emp_no = e.emp_no); -- within the EXISTS() operator subquery there must be a condition relating to the outer/main query. 

	/*
	Exercise: Extract the information about all department managers who were hired between the 1st of January 1990 and the 1st of January 1995.
	*/
	SELECT * FROM employees
	WHERE emp_no IN (SELECT emp_no FROM dept_manager
					 WHERE from_date BETWEEN "1990-01-01" 
						   AND "1995-01-01");
					
	/*
	Exercise: Select the entire information for all employees whose job title is "Assistant Engineer".
	Hint: To solve this exercise, use the 'employees' table.
	*/

	SELECT * FROM employees e 
	WHERE EXISTS (SELECT * FROM titles t
				  WHERE title = 'Assistant Engineer'
						AND t.emp_no = e.emp_no); 
				   


-- STORED PROCEDURE AND FUNCTIONS(USER-DEFINED):
	
    -- Create a procedure that will provide the average salary of every employee.
	DROP PROCEDURE emp_avg_salary;
	DELIMITER /
	CREATE PROCEDURE emp_avg_salary()
	BEGIN 
		SELECT emp_no, AVG(salary)
		FROM salaries
		GROUP BY emp_no;
	END/
	DELIMITER ;

	CALL emp_avg_salary();

	-- Create a procedure called "emp_info" that uses as parameters the first and the last name of an individual, and returns their employee number.
	DROP PROCEDURE emp_info;
	DELIMITER /
	CREATE PROCEDURE emp_info(IN p_first_name VARCHAR(16), IN p_last_name VARCHAR(16), OUT p_emp_no INTEGER)
	BEGIN
		SELECT emp_no 
		INTO p_emp_no
		FROM employees
		WHERE p_first_name = first_name AND p_last_name = last_name;
	END/
	DELIMITER ;

	SET @p_emp_no = 0;
	CALL emp_info("parto", "bamford", @p_emp_no);
	SELECT @p_emp_no AS p_emp_no; -- Just for practice as this procedure gives incorrect output for different employees with same name.


	/* 
	Exercise: Create a function called "emp_info" that takes for parameters the first and last name of an employee, and returns the salary from the newest 
    contract of that employee. Hint: In the BEGIN-END block of this program, you need to declare and use two variables - v_max_from_date that will be 
    of the DATE type, and v_salary, that will be of the DECIMAL (10,2) type.Finally, select this function.
	*/

	DROP FUNCTION emp_info;
	DELIMITER /
	CREATE FUNCTION emp_info(v_first_name VARCHAR(16), v_last_name VARCHAR(16))
	RETURNS DECIMAL(10,2)
	DETERMINISTIC
	BEGIN
	DECLARE v_max_from_date DATE;
	DECLARE v_salary DECIMAL(10,2);
		SELECT 
		MAX(s.from_date)
	INTO v_max_from_date FROM
		employees e
			JOIN
		salaries s ON e.emp_no = s.emp_no
	WHERE
		e.first_name = v_first_name
			AND e.last_name = v_last_name;
		
	SELECT 
		s.salary
	INTO v_salary FROM
		employees e
			JOIN
		salaries s ON e.emp_no = s.emp_no
	WHERE
		e.first_name = v_first_name
			AND e.last_name = v_last_name
			AND v_max_from_date = from_date;
		
		RETURN v_salary;
	END/
	DELIMITER ;

	SELECT emp_info("parto", "bamford");
    
    # create a function that will return the largest salary value of an employee
	DELIMITER /
	CREATE FUNCTION emp_largest_salary(v_emp_no INT)
	RETURNS DECIMAL(10,2) 
	DETERMINISTIC
	BEGIN
	DECLARE v_max_salary DECIMAL(10,2);

	SELECT MAX(salary) INTO v_max_salary
	FROM salaries 
	WHERE emp_no = v_emp_no;

	RETURN v_max_salary;
	END/
	DELIMITER ;

	SELECT emp_largest_salary(110022) AS max_salary;



-- BUILT-IN SQL FUNCTIONS

	SELECT *
	FROM employees 
	WHERE YEAR(hire_date) = '2000'
	ORDER BY first_name;

	SET @v_name = 10;

	SELECT SYSDATE() AS present_date;

	SELECT date_format('2023-01-30', '%y-%m-%d');

	SELECT date_format('2023-01-30', '%Y-%M-%D');
    
    /* 
    Exercise: count the number of contracts registered in the salaries table with a value of higher than or equal to 104038 and duration of more than a year
    using datediff() function
    */
	SELECT COUNT(emp_no)
	FROM salaries
	WHERE salary >= 104038 AND datediff(to_date, from_date) > 365;



- TRIGGERS

	/* 
	Exercise: Create a trigger that checks if the hire date of an employee is higher than the current date. If true, set this date to be the current date. 
	Format the output appropriately (YY-MM-DD).
	*/

	DELIMITER /
	CREATE TRIGGER trig_hire_date1
	BEFORE INSERT ON employees
	FOR EACH ROW
	BEGIN
		IF NEW.hire_date > date_format(sysdate(),'%Y-%m-%d') THEN
		SET NEW.hire_date = date_format(sysdate(),'%y-%m-%d');
		
		END IF;
		
	END/
	DELIMITER ;

	INSERT INTO employees VALUES
	(999904, '1998-07-31','A', 'C', 'M', '2024-01-01');

	UPDATE employees 
	SET hire_date = '2024-01-01'
	WHERE emp_no = 999904;



-- CASE STATEMENT AND IF() CONDITION:

	-- CASE statement
	SELECT emp_no, 
		   first_name, 
		   last_name,
		   CASE WHEN gender = "M" THEN "Male"
		   ELSE "Female"
		   END AS gender
	FROM employees;

	-- another way of using CASE which has limitations i.e. when the choices are binary
	SELECT emp_no,
		   first_name,
		   last_name,
		   CASE gender
		   WHEN 'M' THEN "Male"
		   ELSE "Female"
		   END AS gender
	FROM employees;

	SELECT emp_no,
		   first_name,
		   last_name,
		   IF(gender = 'M',"Male","Female") AS gender
	FROM employees;

	/*
	Exercise: Obtain a result set containing the employee number, and full name of all employees with a number higher than 109990. Create a fourth column 
    in the query, indicating whether this employee is also a manager, according to the data provided in the dept_manager table, or a regular employee.
	*/
	SELECT e.emp_no, 
		   e.first_name,
		   e.last_name,
		   CASE WHEN e.emp_no = dm.emp_no THEN 'Manager'
		   ELSE "Regular Employee"
		   END AS emp_type
	FROM employees e
		 LEFT JOIN
		 dept_manager dm ON e.emp_no = dm.emp_no
	WHERE e.emp_no > 109990;

	/*
	Exercise: Extract a dataset containing the following information about the managers: employee number, full name. Add two columns at the end – one 
    showing the difference between the maximum and minimum salary of that employee, and another saying whether this salary raise was higher than $30,000 or NOT. 
	*/
	SELECT dm.emp_no, 
		   e.first_name, 
		   e.last_name, 
		   MAX(s.salary) - MIN(s.salary) AS salary_diff,
		   CASE WHEN MAX(s.salary) - MIN(s.salary) > 30000 THEN "salary growth more than 30000"
				WHEN MAX(s.salary) - MIN(s.salary) BETWEEN 20000 AND 30000 THEN "salary growth between 20000 and 30000"
				ELSE "poor salary growth or left early"
		   END AS salary_growth
	FROM dept_manager dm 
		 JOIN 
		 employees e ON dm.emp_no = e.emp_no
		 JOIN 
		 salaries s on dm.emp_no = s.emp_no
	GROUP BY dm.emp_no;

	/* 
	Exercise: Extract the employee number, first name, and last name of the first 100 employees, and add a fourth column, called “current_employee” 
	saying “Is still employed” if the employee is still working in the company, or “Not an employee anymore” if they aren’t.
	Hint: You’ll need to use data from both the ‘employees’ and the ‘dept_emp’ table to solve this exercise.
	*/
	SELECT e.emp_no, 
		   e.first_name, 
		   e.last_name,
		   CASE 
		   WHEN MAX(to_date) = '9999-01-01' THEN "Is still employed"
		   ELSE "Not an employee anymore"
		   END AS current_employee
	FROM employees e 
		JOIN
		dept_emp de ON e.emp_no = de.emp_no
	WHERE e.emp_no < 10101
	GROUP BY e.emp_no;










       
       
       
       
       
