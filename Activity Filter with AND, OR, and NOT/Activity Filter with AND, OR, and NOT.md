# Activity: Filter with AND, OR, and NOT

## Solution [here]()

### Run the following Commands

```
SELECT *
FROM log_in_attempts
WHERE login_time > '18:00' AND success = 0;

SELECT *
FROM log_in_attempts
WHERE login_date = '2022-05-09' OR login_date = '2022-05-08';

SELECT * 
FROM log_in_attempts
WHERE NOT country LIKE 'MEX%';

SELECT * 
FROM employees
WHERE department = 'Marketing' AND office LIKE 'East-%';

SELECT * 
FROM employees
WHERE department = 'Finance' OR department = 'Sales';

SELECT * 
FROM employees
WHERE NOT department = 'Information Technology';
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)