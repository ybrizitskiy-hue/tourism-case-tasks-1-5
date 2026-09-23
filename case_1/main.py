"""Кейс-задача № 1.

Найти сумму отрицательных элементов одномерного массива,
расположенных между максимальным и минимальным элементами.
"""

import math


def sum_negative_between_min_max(values: list[float]) -> float:
    """Возвращает сумму отрицательных элементов между min и max.

    Если минимальный или максимальный элемент встречается несколько раз,
    используется его первое вхождение.
    """
    if len(values) < 2:
        raise ValueError("Массив должен содержать не менее двух элементов")
    if not all(math.isfinite(value) for value in values):
        raise ValueError("Все элементы массива должны быть конечными числами")

    min_index = values.index(min(values))
    max_index = values.index(max(values))

    left = min(min_index, max_index) + 1
    right = max(min_index, max_index)

    return sum(value for value in values[left:right] if value < 0)


def read_array() -> list[float]:
    """Считывает размер и элементы массива с клавиатуры."""
    while True:
        try:
            n = int(input("Введите размер массива N: "))
            if n < 2:
                print("N должно быть не меньше 2.")
                continue
            break
        except ValueError:
            print("Введите целое число.")

    while True:
        raw = input(f"Введите {n} чисел через пробел: ")
        try:
            values = [float(item) for item in raw.split()]
        except ValueError:
            print("Все элементы массива должны быть числами.")
            continue

        if not all(math.isfinite(value) for value in values):
            print("Все элементы массива должны быть конечными числами.")
            continue

        if len(values) != n:
            print(f"Требуется ровно {n} элементов. Получено: {len(values)}.")
            continue

        return values


def main() -> None:
    values = read_array()

    min_value = min(values)
    max_value = max(values)
    min_index = values.index(min_value)
    max_index = values.index(max_value)
    result = sum_negative_between_min_max(values)

    print("\nИсходный массив:", values)
    print(f"Минимальный элемент: {min_value}, индекс: {min_index}")
    print(f"Максимальный элемент: {max_value}, индекс: {max_index}")
    print("Сумма отрицательных элементов между ними:", result)


if __name__ == "__main__":
    main()
