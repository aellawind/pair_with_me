# -*- coding: utf-8 -*-
# Generated by Django 1.11.2 on 2017-06-18 00:02
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Food',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, default='', max_length=100)),
            ],
        ),
        migrations.CreateModel(
            name='Wine',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, default='', max_length=100)),
                ('foods', models.ManyToManyField(blank=True, to='api.Food')),
            ],
        ),
        migrations.AddField(
            model_name='food',
            name='wines',
            field=models.ManyToManyField(blank=True, to='api.Wine'),
        ),
    ]
