# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import django_filters.rest_framework
from rest_framework import (
    generics,
    mixins,
)

from api.models import (
    Food,
    Wine,
)
from api.serializers import (
    FoodSerializer,
    WineSerializer,
    WineDetailSerializer,
    FoodDetailSerializer,
)


class FoodList(generics.ListCreateAPIView):
    queryset = Food.objects.all()
    serializer_class = FoodSerializer
    filter_backends = (django_filters.rest_framework.DjangoFilterBackend,)
    filter_fields = ('name', 'description')


class FoodDetail(mixins.RetrieveModelMixin, generics.GenericAPIView):
    queryset = Food.objects.all()
    serializer_class = FoodDetailSerializer

    def get(self, request, *args, **kwargs):
        return self.retrieve(request, *args, **kwargs)


class WineList(generics.ListCreateAPIView):
    queryset = Wine.objects.all()
    serializer_class = WineSerializer
    filter_backends = (django_filters.rest_framework.DjangoFilterBackend,)
    filter_fields = ('name', 'description')


class WineDetail(mixins.RetrieveModelMixin, generics.GenericAPIView):
    queryset = Wine.objects.all()
    serializer_class = WineDetailSerializer

    def get(self, request, *args, **kwargs):
        return self.retrieve(request, *args, **kwargs)
