"""Классы предметной области для кейс-задачи № 2."""


class Tour:
    """Базовый класс, описывающий туристический тур."""

    def __init__(self, title: str, country: str, days: int, price: float) -> None:
        self.title = title
        self.country = country
        self.days = days
        self.price = price

    def get_description(self) -> str:
        """Возвращает описание тура."""
        return (
            f"Тур: {self.title}\n"
            f"Страна: {self.country}\n"
            f"Продолжительность: {self.days} дн.\n"
            f"Стоимость: {self.price:.2f} EUR"
        )

    def calculate_total(self, tourists: int) -> float:
        """Рассчитывает стоимость тура для указанного числа туристов."""
        if tourists <= 0:
            raise ValueError("Количество туристов должно быть положительным")
        return self.price * tourists


class BeachTour(Tour):
    """Производный класс для пляжного тура."""

    def __init__(
        self,
        title: str,
        country: str,
        days: int,
        price: float,
        hotel: str,
        distance_to_beach: int,
    ) -> None:
        super().__init__(title, country, days, price)
        self.hotel = hotel
        self.distance_to_beach = distance_to_beach

    def get_description(self) -> str:
        """Дополняет описание данными, характерными для пляжного тура."""
        base_description = super().get_description()
        return (
            f"{base_description}\n"
            f"Тип тура: пляжный\n"
            f"Отель: {self.hotel}\n"
            f"Расстояние до пляжа: {self.distance_to_beach} м"
        )

    def beach_info(self) -> str:
        """Метод, определенный только в производном классе."""
        return (
            f"Отель «{self.hotel}» расположен в "
            f"{self.distance_to_beach} м от пляжа."
        )
