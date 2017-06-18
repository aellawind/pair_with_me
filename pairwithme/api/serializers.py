from rest_framework import serializers
from api.models import (
    Food,
    Wine,
)


class FoodSerializer(serializers.ModelSerializer):
    class Meta:
        model = Food
        fields = ['name', 'id']


class WineSerializer(serializers.ModelSerializer):
    class Meta:
        model = Wine
        fields = ['name', 'id']


class WineDetailSerializer(serializers.ModelSerializer):
    foods = FoodSerializer(read_only=True, many=True)

    class Meta:
        model = Wine
        fields = ['name', 'id', 'foods']


class FoodDetailSerializer(serializers.ModelSerializer):
    wines = WineSerializer(read_only=True, many=True)

    class Meta:
        model = Food
        fields = ['name', 'id', 'wines']
