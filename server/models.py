from django.db import models
from django.forms import model_to_dict


def create_dict(model: models.Model) -> dict:
    d: dict = model_to_dict(model)
    model_type: type = type(model)
    
    d["id"] = model.id 
    d["model_type"] = model_type.__name__

    if model_type == Actor:
        d["instanced_entity"] = create_dict(model.instanced_entity)
        
    elif model_type == InstancedEntity:
        d["entity"] = create_dict(model.entity)
        if "entity_id" in d:
            del d["entity_id"]
    
    return d
    


class User(models.Model):
    username = models.CharField(unique=True, max_length=20)
    password = models.CharField(max_length=99)
    IsAdmin = models.BooleanField(default=False)

class Entity(models.Model):
    name = models.CharField(unique=True, max_length=16)

class InstancedEntity(models.Model):
    entity = models.ForeignKey(Entity, on_delete=models.CASCADE)
    x = models.FloatField()
    y = models.FloatField()
    Rocks = models.IntegerField(default=0)

class Actor(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    instanced_entity = models.OneToOneField(InstancedEntity, on_delete=models.CASCADE)
    avatar_id = models.IntegerField(default=4)

class WorldNode(models.Model):
    node_type = models.IntegerField()
    x = models.FloatField()
    y = models.FloatField()
    RespawnTimer = models.FloatField(default=0.0)
    active = models.BooleanField(default=True)