"""Тестовая программа для демонстрации базового и производного классов."""

from models import BeachTour, Tour


def main() -> None:
    print("=== Объект базового класса Tour ===")
    city_tour = Tour(
        title="Выходные в Риме",
        country="Италия",
        days=3,
        price=420.0,
    )
    print(city_tour.get_description())
    print(f"Стоимость для 2 туристов: {city_tour.calculate_total(2):.2f} EUR")

    print("\n=== Объект производного класса BeachTour ===")
    beach_tour = BeachTour(
        title="Отдых на Солнечном Берегу",
        country="Болгария",
        days=7,
        price=650.0,
        hotel="Sea Resort",
        distance_to_beach=150,
    )
    print(beach_tour.get_description())
    print(f"Стоимость для 3 туристов: {beach_tour.calculate_total(3):.2f} EUR")
    print(beach_tour.beach_info())

    print("\n=== Полиморфный вызов get_description() ===")
    tours: list[Tour] = [city_tour, beach_tour]
    for tour in tours:
        print("-" * 40)
        print(tour.get_description())


if __name__ == "__main__":
    main()
