# Activity: Filter a SQL query

## Solution [here]()

### Run the following Commands in CloudShell

```
SELECT device_id, operating_system
FROM machines;

SELECT device_id, operating_system
FROM machines
WHERE operating_system = 'OS 2';

SELECT *
FROM employees
WHERE department = 'Finance';

SELECT *
FROM employees
WHERE department = 'Sales';

SELECT *
FROM employees
WHERE office = 'South-109';

SELECT *
FROM employees
WHERE office LIKE 'South%';
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)