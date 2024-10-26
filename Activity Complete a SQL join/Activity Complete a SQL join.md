# Activity: Complete a SQL join

## Solution [here]()

### Run the following Commands

```
SELECT * 
FROM machines;

SELECT * 
FROM machines 
INNER JOIN employees ON machines.device_id = employees.device_id;

SELECT *
FROM machines
LEFT JOIN employees ON machines.device_id = employees.device_id;

SELECT *
FROM machines
RIGHT JOIN employees ON machines.device_id = employees.device_id;

SELECT * 
FROM employees 
INNER JOIN log_in_attempts ON employees.username = log_in_attempts.username;
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)