# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models


class Food(models.Model):
    name = models.CharField(max_length=100, blank=True, default='')


class Wine(models.Model):
    name = models.CharField(max_length=100, blank=True, default='')
    foods = models.ManyToManyField(Food, related_name='wines')