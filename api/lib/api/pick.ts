import { Metric, Point, User, Workout } from "@prisma/client";
import { p } from "./pick-helper";

export const pick = {
  User: p<User>(
    "id",
    "phone_number",
    "name",
    "created_at",
    "updated_at",
    "avatar",
    "dummy"
  ),
  Metric: p<Metric>(
    "id",
    "name",
    "created_at",
    "updated_at",
    "user_id",
    "unit",
    "step_size",
    "default_value",
    "default_sets"
  ),
  Workout: p<Workout>(
    "id",
    "created_at",
    "updated_at",
    "user_id",
    "start_date",
    "end_date",
    "archived",
    "plan_id"
  ),
  Point: p<Point>(
    "id",
    "created_at",
    "updated_at",
    "metric_id",
    "value",
    "workout_id",
    "planned"
  ),
};
