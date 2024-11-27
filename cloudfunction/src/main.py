import base64
import json
import os
import re
from distutils.util import strtobool
from google.cloud import aiplatform
from kfp.registry import RegistryClient

from cloudevents.http import CloudEvent
import functions_framework

# Source: https://cloud.google.com/functions/docs/tutorials/pubsub
@functions_framework.cloud_event
def cf_handler(cloud_event: CloudEvent) -> None:
    data_ = base64.b64decode(cloud_event.data["message"]["data"]).decode()
    payload = json.loads(data_)
    
    try:
        print(f'...Converting event to JSON.')
        event = json.loads(cloud_event)
    except Exception as e:
        print(f'...Event is already a JSON or another error: {e}.')
        print(f'...Continuing.')
        print(f'...')
        print(f'...')
        event = cloud_event
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Event:")
    print(event)
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    
    project_id = os.environ["VERTEX_PROJECT_ID"]
    location = os.environ["VERTEX_LOCATION"]
    pipeline_root = os.environ["VERTEX_PIPELINE_ROOT"]
    service_account = os.environ["VERTEX_SA_EMAIL"]
    
    try: # IF IT COMES FROM EVENT GCS:
        from_ = "event_trigger"
        
        template_path = f"https://{event.data['message']['attributes']['template_path']}"
        display_name = event.data['message']['attributes']['display_name']
        
        try:
            pipeline_parameters = event.data['message']['attributes']['pipeline_parameters']
        except:
            print("...Couldn't obtain pipeline parameters, using template's default.")
            pipeline_parameters = "{}"
         
        enable_caching = event.data['message']['attributes']['enable_caching']
        print(f'[RECEIVED MESSAGE FROM EVENT TRIGGER]')
        
    except Exception as e: # IF IT COMES FROM EVENT CRON:
        from_ = "cron_trigger"
        
        template_path = f'https://{payload["template_path"]}'
        display_name = payload["display_name"]  
        pipeline_parameters = payload.get("pipeline_parameters")
        enable_caching = payload.get("enable_caching")
        
        print(f'[RECEIVED MESSAGE FROM CRON TRIGGER]')
        
    try:
        print(f'...Converting pipeline parameters to JSON.')
        pipeline_parameters = json.loads(pipeline_parameters)
    except Exception as e:
        print(f"... Pipeline parameters are already a JSON or another error: {e}.")
        print(f'...Continuing.')
        print(f'...')
        print(f'...')
        
    print(">>>>>>><>>>>>>>>>>>>>>>>>>>>> Template:")
    print(template_path)
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    

    print(">>>>>>>>> Provided Pipeline Parameters:")
    print(pipeline_parameters)
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")

    if enable_caching:
        enable_caching = bool(strtobool(enable_caching))
    print(">>>>>>>>>>>>>>>>>>>>>>> Enable Caching:")
    print(enable_caching)
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")

    # For below options, we want an empty string to become None, so we add "or None"
    encryption_spec_key_name = os.environ.get("VERTEX_CMEK_IDENTIFIER") or None
    network = os.environ.get("VERTEX_NETWORK") or None

    # If template_path is an AR URL and a tag is used, resolve to exact version
    # Workaround for known issue
    # https://github.com/googleapis/python-aiplatform/issues/2181
    _VALID_AR_URL = re.compile(
        r"https://([\w\-]+)-kfp\.pkg\.dev/([\w\-]+)/([\w\-]+)/([\w\-]+)/([\w\-.]+)",
        re.IGNORECASE,
    )
    match = _VALID_AR_URL.match(template_path)
    if match and "sha256:" not in template_path:
        region, project, repo, package_name, tag = match.group(1, 2, 3, 4, 5)
        host = f"https://{region}-kfp.pkg.dev/{project}/{repo}"
        client = RegistryClient(host=host)
        metadata = client.get_tag(package_name, tag)
        version = metadata["version"][metadata["version"].find("sha256:") :]
        template_path = f"{host}/{package_name}/{version}"

    # Instantiate PipelineJob object:
    if not pipeline_parameters:
        pipeline_parameters = None
        print("Using default pipeline parameters as {} was provided.")
        
    pl = aiplatform.pipeline_jobs.PipelineJob(
        project=project_id,
        location=location,
        display_name=display_name,
        enable_caching=enable_caching,
        template_path=template_path.replace("_","-"),
        parameter_values=pipeline_parameters,
        pipeline_root=pipeline_root,
        encryption_spec_key_name=encryption_spec_key_name,
        labels={"trigger":from_},
    )
    
    # Execute pipeline in Vertex
    pl.submit(
        service_account=service_account,
        network=network,
    )