# Filtering and Sorting Data in Looker || [GSP855](https://www.cloudskillsboost.google/focuses/17740?parent=catalog) ||

## 🔑 Solution [here]()

### 🔧 Replace the contents of `faa.model` with the following code

```
connection: "bigquery_public_data_looker"
# include all views in this project
include: "*.view"
include: "/z_tests/*.lkml"

explore: airports {
  group_label: "FAA"
}

explore: flights {
  group_label: "FAA"
  description: "Start here for information about flights!"
  join: carriers {
    type: left_outer
    sql_on: ${flights.carrier} = ${carriers.code} ;;
    relationship: many_to_one
  }

  join: aircraft {
    type: left_outer
    sql_on: ${flights.tail_num} = ${aircraft.tail_num} ;;
    relationship: many_to_one
  }

  join: aircraft_origin {
    from: airports
    type: left_outer
    sql_on: ${flights.origin} = ${aircraft_origin.code} ;;
    relationship: many_to_one
    fields: [full_name, city, state, code, map_location]
  }

  join: aircraft_destination {
    from: airports
    type: left_outer
    sql_on: ${flights.destination} = ${aircraft_destination.code} ;;
    relationship: many_to_one
    fields: [full_name, city, state, code, map_location]
  }

  join: aircraft_models {
    sql_on: ${aircraft.aircraft_model_code} = ${aircraft_models.aircraft_model_code} ;;
    relationship: many_to_one
  }
}

explore: +flights {
    query: task_1 {
      dimensions: [depart_week]
      measures: [cancelled_count]
      filters: [flights.depart_date: "2004"]
    }
  }

explore: +flights {
  query: task_2 {
    dimensions: [carriers.name]
    measures: [count_long_flight, total_distance]
    filters: [flights.percentage_long_flights: ""]
    }
  }
```

* Title the 1st Look as
```
Cancelled Flight Count by Week in 2004
```
* Title the 2nd Look as
```
Total Distance and Long Flight Count by Carrier
```

# 🎉 Woohoo! You Did It! 🎉

Your hard work and determination paid off! 💻
You've successfully completed the lab. **Way to go!** 🚀

### 💬 Stay Connected with Our Community!

👉 Join the conversation and never miss an update:

💚 [𝗪𝗵𝗮𝘁𝘀𝗔𝗽𝗽 𝗖𝗼𝗺𝗺𝘂𝗻𝗶𝘁𝘆](https://chat.whatsapp.com/ECJ9h8GA3CA1ksaI9m5NrX)
📢 [Telegram Channel](https://t.me/quickgcplab)
👥 [Discussion Group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)