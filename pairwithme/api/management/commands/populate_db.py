from django.core.management.base import BaseCommand
from api.models import (
    Food,
    Wine,
)


class Command(BaseCommand):
    """Run with python manage.py populate_db"""
    help = 'Populate database with fake food and wine pairings'

    def _wine_and_food(self):
        pairings = {
            'olives': 'cabernet',
            'cherries': 'syrah',
            'chocolate': 'pinot',
            'honey': 'rose',
            'rasberry': 'chardonnay',
            'lemon': 'shiraz',
            'cheese': 'merlot',
        }
        for food, wine in pairings.items():
            food = Food.objects.create(name=food)
            wine = Wine.objects.create(name=wine)
            food.wines.add(wine)

    def handle(self, *args, **options):
        self._wine_and_food()
