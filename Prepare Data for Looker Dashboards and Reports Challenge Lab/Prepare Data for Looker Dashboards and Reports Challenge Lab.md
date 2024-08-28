# Prepare Data for Looker Dashboards and Reports: Challenge Lab || [GSP346](https://www.cloudskillsboost.google/focuses/18116?parent=catalog) ||

## Solution [here](https://youtu.be/nqm6FQTOICI)

### Task 1. Create Looks

#### Look #1: Most heliports by state

1. In the **Looker navigation menu**, click **Explore**.
2. Under **FAA**, click ****Airports****.
3. Under **Airports** > **Dimensions**, click **City**.
4. Under **Airports** > **Dimensions**, click **State**.
5. Under **Airports** > **Measures**, click **Count**.
6. Under **Airports** > **Dimensions**, click on the **Filter** button next to the **Facility Type**.
7. In the **filter window**, set the **filter** to: is equal to **`HELIPORT`**.
8. On the **Data tab**, change **Row limit** to **YOUR LIMIT**
9. Click **Run**
10. Click on **Airports Count** to sort the values in **descending order**.
11. Click the arrow next to **Visualization** to expand the window.
12. Change **visualization** type to **Table**.
13. Click **Run**.
14. Click on the **settings gear** icon next to **Run**, and select **Save** > **As a Look**.
15. Title the **NAME YOUR LOOK**.
16. Click **Save**.

#### Look #2: Facility type breakdown

1. In the **Looker navigation menu**, click **Explore**.
2. Under **FAA**, click **Airports**.
3. Under **Airports** > **Dimensions**, click **State**.
4. Under **Airports** > **Measures**, click **Count**.
5. Under **Airports** > **Dimensions**, click on the **Pivot button** next to the **Facility Type**.
6. On the **Data tab**, change **Row limit** to **YOUR LIMIT**
7. Click on **Airports Facility Type** to sort the values in **descending order**.
8. Click the arrow next to **Visualization** to expand the window.
9. Change **visualization** type to **Table**.
10. Click **Run**.
11. Click on the **settings gear** icon next to **Run**, and select **Save** > **As a Look**.
12. Title the **NAME YOUR LOOK**.
13. Click **Save**.

#### Look #3: Percentage cancelled

1. In the **Looker navigation menu**, **click** **Explore**.
2. Under **FAA**, click **Flights**.
3. Under **Aircraft Origin** > **Dimensions**, click **City**.
4. Under **Aircraft Origin** > **Dimensions**, click **State**.
5. Under **Flights Details** > **Measures**, click **Cancelled Count**.
6. Under **Flights** > **Measures**, click **Count**.
7. Under **Flights** > **Measures**, click on the **Filter** button next to the **Count**.
8. In the **filter window**, set the **filter** to: Flights Count **is greater than `10000`**.
9. Click **Run**.
10. Next to **Custom Fields**, click **+ Add**. Select **Table Calculation**.
11. Copy or Paste the following in **Expression field**:
```
${flights.cancelled_count}/${flights.count}
```
12. Name The Calculation **`Percentage of Flights Cancelled`**
13. Click **Default Formatting** to change the format to **Percent (3)**
14. Click on **Percent Cancelled** to sort the values in **descending order**.
15. Hover over the **Flights Count column**, and click the **gear icon** that appears on the right side.
16. Click **Hide from Visualization**.
17. Hover over the **Cancelled Count column**, and click the **gear icon** that appears on the right side.
18. Click **Hide from Visualization**.
19. Change **visualization** type to **Table**.
20. Click **Run**.
21. Click on the **settings gear** icon next to **Run**, and select **Save** > **As a Look**.
22. Title the type or paste the following:
```
States and Cities with Highest Percentage of Cancellations: Flights over 10,000
```
23. Click **Save**.

#### Look #4: Smallest average distance

1. In the **Looker navigation menu**, click **Explore**.
2. Under **FAA**, click **Flights**.
3. Under **Flights** > **Dimensions**, click **Origin and Destination**.
4. Next to **Custom Fields**, click **+ Add**. Select **Custom Measure**.
5. In Field to **Measure**, type or  paste the following
```
Average Distance
```
6. Name The Custom Measure: **`Average Distance (Miles)`**
7. Click **Save**.
8. Hover over the **Average Distance (Miles) column**, and click the **gear icon** that appears on the right side.
9. Click **Filter**.
10. In the **filter window**, set the filter to: **Average Distance (Miles) is greater than `0`**
11. Click on **Average Distance (Miles)** to sort the values in **Ascending order**.
12. On the **Data tab**, change **Row limit** to **YOUR LIMIT**.
13. Click the arrow next to **Visualization** to expand the window.
14. Change **visualization** type to **Table**.
15. Click **Run**.
16. Click on the **settings gear** icon next to **Run**, and select **Save** > **As a Look**.
17. Title the **NAME YOUR LOOK**.
18. Click **Save**.

### Task 2. Merge results

1. In the **Looker navigation menu**, click **Explore**.
2. Under **FAA**, click **Flights**.
3. Under **Aircraft Origin** > **Dimensions**, click **City**.
4. Under **Aircraft Origin** > **Dimensions**, click **State**.
5. Under **Aircraft Origin** > **Dimensions**, click **Code**.
6. Under **Flights** > **Measures**, click **Count**.
7. On the **Data tab**, change **Row limit** to `10`
8. Click **Run**.
9. In the top right pane of the **Explore** for your **primary query**, click **Settings (Settings/gear)**.
10. Click **Merge Results**. This will open the Choose an **Explore window**.
11. In the Choose an **Explore window**, click **Airports**.
12. In the **All Fields pane**, click **City**, **State** and **Code**.
13. Under **Airports** > **Dimensions**, click on the **Filter** button next to the **Control Tower (Yes / No)**.
14. In the **filter window**, set the **filter** to: **Airports Control Tower (Yes / No)** is **Yes**.
15. Under **Airports** > **Dimensions**, click on the **Filter** button next to the **Is Major (Yes / No)**.
16. In the **filter window**, set the **filter** to: **Airports Is Major (Yes / No)** is **Yes**.
17. Under **Airports** > **Dimensions**, click on the **Filter** button next to the **Joint Use (Yes / No)**.
18. In the **filter window**, set the **filter** to: **Airports Joint Use (Yes / No)** is **Yes**.
19. Click **Run** to see the results of the source query.
20. Click **Save** to merge the query into your primary query.
21. Click **Run** to view the results of your merged results.
22. Click the arrow next to **Visualization** to expand the window.
23. Change **visualization** type to **Bar**.
24. Click **Run**.
25. In the top right pane of the Explore for your **Merged Results**, click the **gear icon**.
26. Click **Save to Dashboard**.
27. For **Title**, type or  paste
```
Busiest, Major Joint-Use Airports with Control Towers
```
28. Click **New Dashboard**.
29. For the **dashboard name**, type **YOUR DASHBOARD NAME** and click **OK**
30. Click **Save to Dashboard**.

### Task 3: Save looks to a dashboard

1. In the **Looker navigation menu**, click **Folders**.
2. Select **My folder**.
> You should see the Looks you just created.
3. Click on the **YOUR DASHBOARD NAME**.
4. Click on the **settings gear** icon next to **Run**, and select **Save** > **To an existing dashboard**.
5. Select the **dashbo**ard you **previously created**
6. Click **Add Look to Dashboard**.
7. For each of the **Looks you created**, add them to the **YOUR DASHBOARD NAME**.

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
