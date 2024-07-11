# Troubleshooting Data Models in Looker || [GSP1019](https://www.cloudskillsboost.google/focuses/33371?parent=catalog) ||

## Solution [here](https://youtu.be/Bhttc3GIF3c)

1. Create a `.view` file name `user_order_lifetime` and paste the following:

```
view: user_order_lifetime {
  derived_table: {
    sql: SELECT
        order_items.user_id as user_id
         ,COUNT(*) as lifetime_orders
         ,SUM(order_items.sale_price) as lifetime_sales
      FROM cloud-training-demos.looker_ecomm.order_items
      GROUP BY user_id

      ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: user_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: lifetime_orders {
    type: number
    sql: ${TABLE}.lifetime_orders ;;
  }

  dimension: lifetime_sales {
    type: number
    sql: ${TABLE}.lifetime_sales ;;
  }

  set: detail {
    fields: [user_id, lifetime_orders, lifetime_sales]
  }
}
```

2. Replace and paste the followin in  `users.view` file:

```
view: users {
  sql_table_name: `cloud-training-demos.looker_ecomm.users`
    ;;
  drill_fields: [id]

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: age {
    type: number
    sql: ${TABLE}.age ;;
  }

  dimension: city {
    type: string
    sql: ${TABLE}.city ;;
  }

  dimension: country {
    type: string
    map_layer_name: countries
    sql: ${TABLE}.country ;;
  }

  dimension_group: created {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.created_at ;;
  }

  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
  }

  dimension: first_name {
    type: string
    sql: ${TABLE}.first_name ;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }

  dimension: last_name {
    type: string
    sql: ${TABLE}.last_name ;;
  }

  dimension: latitude {
    type: number
    sql: ${TABLE}.latitude ;;
  }

  dimension: longitude {
    type: number
    sql: ${TABLE}.longitude ;;
  }

  dimension: state {
    type: string
    sql: ${TABLE}.state ;;
    map_layer_name: us_states
  }

  dimension: traffic_source {
    type: string
    sql: ${TABLE}.traffic_source ;;
  }

  dimension: zip {
    type: zipcode
    sql: ${TABLE}.zip ;;
  }

  dimension: average_sales {
    type: number
    sql: ${user_order_lifetime.lifetime_sales} / ${user_order_lifetime.lifetime_orders} ;;
    value_format_name: usd
  }
  
  dimension: average_order_price  {
    type: number
    sql: ${user_order_lifetime.lifetime_sales} / ${user_order_lifetime.lifetime_orders} ;;
    value_format_name: usd
  }

  measure: count {
    type: count
    drill_fields: [id, last_name, first_name, events.count, order_items.count]
  }
}
```

3. Copy and paste the follwing in `training_ecommerce` model.

```
connection: "bigquery_public_data_looker"

# include all the views
include: "/views/*.view"
include: "/z_tests/*.lkml"
include: "/**/*.dashboard"

datagroup: training_ecommerce_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: training_ecommerce_default_datagroup

label: "E-Commerce Training"

explore: order_items {
  
  query: LOL {
    dimensions: [users.age, users.average_sales, users.country, users.id, users.state]
  }
  join: user_order_lifetime {
    type: left_outer
    sql_on: ${order_items.user_id} = ${user_order_lifetime.user_id} ;;
    relationship: many_to_one
  }
  
  join: users {
    type: left_outer
    sql_on: ${order_items.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
  
  join: inventory_items {
    type: left_outer
    sql_on: ${order_items.inventory_item_id} = ${inventory_items.id} ;;
    relationship: many_to_one
  }
  
  join: products {
    type: left_outer
    sql_on: ${inventory_items.product_id} = ${products.id} ;;
    relationship: many_to_one
  }
  
  join: distribution_centers {
    type: left_outer
    sql_on: ${products.distribution_center_id} = ${distribution_centers.id} ;;
    relationship: many_to_one
  }
}

explore: events {
  join: event_session_facts {
    type: left_outer
    sql_on: ${events.session_id} = ${event_session_facts.session_id} ;;
    relationship: many_to_one
  }
  join: event_session_funnel {
    type: left_outer
    sql_on: ${events.session_id} = ${event_session_funnel.session_id} ;;
    relationship: many_to_one
  }
  join: order_items {
    type: left_outer
    sql_on: ${events.user_id} = ${order_items.user_id} ;;
    relationship: many_to_one
  }
  join: users {
    type: left_outer
    sql_on: ${events.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
  
  join: user_order_lifetime {
    type: left_outer
    sql_on: ${order_items.user_id} = ${user_order_lifetime.user_id} ;;
    relationship: many_to_one
  }
  
}
```
* ### For Tasks 3 Follow [Video](https://youtu.be/Bhttc3GIF3c) Instructions.

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
