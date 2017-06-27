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
            1: {
                'food': 'olives',
                'wine':'cabernet',
                'description': 'Also goes well with chocolate and rose',
            },
            2: {
                'food': 'cherries',
                'wine':'syrah',
                'description': 'Also goes well with chocolate and rose',
            },
            3: {
                'food': 'chocolate',
                'wine':'pinot',
                'description': 'Hello shiraz why are you so pretty',
            },
            4: {
                'food': 'honey',
                'wine':'rose',
                'description': 'Lemon lemon lemon chocolate chocolate pinot',
            },
            5: {
                'food': 'raspberry',
                'wine':'chardonnay',
                'description': 'Cherries can be interchanged for raspberry',
            },
            6: {
                'food': 'lemon',
                'wine':'shiraz',
                'description': 'Honey walnut prawns as well',
            },
            7: {
                'food': 'cheese',
                'wine':'merlot',
                'description': 'Delicious fondue, brie, fig preserves'
            },
        }
        for num, obj in pairings.items():
            food = Food.objects.create(
                name=obj['food'],
                description=obj['description'],
            )
            wine = Wine.objects.create(
                name=obj['wine'],
                description=obj['description'],
            )
            food.wines.add(wine)

    def handle(self, *args, **options):
        self._wine_and_food()
