import argparse
from typing import List
from google.cloud import storage

import json
import os

def handle_pipeline_params(attributes):
    try:
        attributes = json.loads(attributes)
    except:
        print("Attributes already a JSON.")
    params = attributes['pipeline_parameters']
    attributes['pipeline_parameters'] = json.dumps(params)
    return attributes

def create_bucket_notifications(bucket_name, topic_name, custom_attributes=None, event_types=None, blob_name_prefix=None, payload_format="JSON_API_V1"):
    """Creates a notification configuration for a bucket."""
    storage_client = storage.Client()
    bucket = storage_client.bucket(
        bucket_name=bucket_name,
    )
    notification = bucket.notification(
        topic_name=topic_name,
        custom_attributes=handle_pipeline_params(custom_attributes), 
        event_types=event_types, 
        blob_name_prefix=blob_name_prefix, 
        payload_format=payload_format,
    )
    notification.create()

    print(f"# Successfully created notification!")
    print("################################################################################")
    return notification.notification_id

def list_bucket_notifications(bucket_name):
    """Lists notification configurations for a bucket."""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    notifications = bucket.list_notifications()

    for notification in notifications:
        print(f"Notification ID: {notification.notification_id}")

# Shell command: gcloud storage buckets notifications list bucket_name
def print_pubsub_bucket_notification(bucket_name, notification_id):
    """Gets a notification configuration for a bucket."""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    notification = bucket.get_notification(notification_id)

    print(f"Notification ID: {notification.notification_id}")
    print(f"Topic Name: {notification.topic_name}")
    print(f"Event Types: {notification.event_types}")
    print(f"Custom Attributes: {notification.custom_attributes}")
    print(f"Payload Format: {notification.payload_format}")
    print(f"Blob Name Prefix: {notification.blob_name_prefix}")
    print(f"Etag: {notification.etag}")
    print(f"Self Link: {notification.self_link}")
    
    return notification

def delete_bucket_notification(bucket_name, notification_id):
    """Deletes a notification configuration for a bucket."""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    notification = bucket.notification(notification_id=notification_id)
    notification.delete()

    print(f"Successfully deleted notification with ID {notification_id} for bucket {bucket_name}")

def main(args: List[str] = None):
    """CLI entrypoint for the upload_pipeline.py script"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--bucket", type=str, required=True)
    parser.add_argument("--topic_name", type=str, required=False)
    parser.add_argument("--custom_attributes", type=str, required=False)
    parser.add_argument("--event_types", type=str, action="append")
    parser.add_argument("--blob_name_prefix", type=str, required=False)
    parser.add_argument("--payload_format", type=str, required=False)
    parser.add_argument("--function", type=str, required=False)
    parser.add_argument("--notification_id", type=int, required=False)
    parsed_args = parser.parse_args(args)
    
    if parsed_args.bucket.startswith("gs://"):
        bucket = parsed_args.bucket[5:]
    else:
        bucket = parsed_args.bucket
   
    if parsed_args.function:
        if parsed_args.function == "list":
            list_bucket_notifications(bucket)
        elif parsed_args.function == "details":
            print_pubsub_bucket_notification(bucket, parsed_args.notification_id)
        elif parsed_args.function == "delete":
            delete_bucket_notification(bucket, parsed_args.notification_id)
        else:
            print(f"Unsported argument function: {parsed_args.function}")
    else:   
        notification_id = create_bucket_notifications(
            bucket_name=bucket, 
            topic_name=parsed_args.topic_name, 
            custom_attributes=json.loads(parsed_args.custom_attributes),  
            event_types=parsed_args.event_types,
            blob_name_prefix=parsed_args.blob_name_prefix,
            payload_format=parsed_args.payload_format,
        )
    
        print(f"#     Custom attributes in Pub/Sub message: {json.loads(parsed_args.custom_attributes)}")
        print(f"#     Bucket Event Notification ID: {notification_id}")

if __name__ == "__main__":
    main()