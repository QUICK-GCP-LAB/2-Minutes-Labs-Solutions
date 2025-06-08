# Creating Derived Tables Using LookML || [GSP858](https://www.cloudskillsboost.google/focuses/18475?parent=catalog) ||

## 🔑 Solution [here]()

1. **Create a new view file** named `order_details`  
2. **Remove** the default code.  
3. **Paste** the following LookML:  

```lookml
view: order_details {
  derived_table: {
    sql: SELECT
        order_items.order_id AS order_id,
        order_items.user_id AS user_id,
        COUNT(*) AS order_item_count,
        SUM(order_items.sale_price) AS order_revenue
      FROM cloud-training-demos.looker_ecomm.order_items
      GROUP BY order_id, user_id ;;
  }

  measure: count {
    hidden: yes
    type: count
    drill_fields: [detail*]
  }

  dimension: order_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: order_item_count {
    type: number
    sql: ${TABLE}.order_item_count ;;
  }

  dimension: order_revenue {
    type: number
    sql: ${TABLE}.order_revenue ;;
  }

  set: detail {
    fields: [order_id, user_id, order_item_count, order_revenue]
  }
}
```

---

1. **Create a new view file** named `order_details_summary`  
2. **Remove** the default code.  
3. **Paste** the following LookML:  

```lookml
# If necessary, uncomment the line below to include explore_source.
# include: "training_ecommerce.model.lkml"

view: add_a_unique_name_1718592811 {
  derived_table: {
    explore_source: order_items {
      column: order_id {}
      column: user_id {}
      column: order_count {}
      column: total_revenue {}
    }
  }

  dimension: order_id {
    description: ""
    type: number
  }

  dimension: user_id {
    description: ""
    type: number
  }

  dimension: order_count {
    description: ""
    type: number
  }

  dimension: total_revenue {
    description: ""
    value_format: "$#,##0.00"
    type: number
  }
}
```

---

1. Open the file named: `training_ecommerce.model`  

2. Replace the content:  

```lookml
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
  join: order_details {
    type: left_outer
    sql_on: ${order_items.order_id} = ${order_details.order_id} ;;
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

  join: users {
    type: left_outer
    sql_on: ${events.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
}
```

# 🎉 Woohoo! You Did It! 🎉

Your hard work and determination paid off! 💻  
You've successfully completed the lab. Way to go! 🚀  

### 💬 Stay Connected with Our Community!

👉 Join the conversation and never miss an update:  

💚 [WhatsApp Community](https://chat.whatsapp.com/ECJ9h8GA3CA1ksaI9m5NrX)  
📢 [Telegram Channel](https://t.me/quickgcplab)  
👥 [Discussion Group](https://t.me/quickgcplabchats)  

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)