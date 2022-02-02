from random import randint

# характеристики населения:
AGE_MIN = 0		# минимальный возраст
AGE_MAX = 120		# максимальный возраст
POPULATION = 1_000_000	# всего население

# сгененируем тестовый массив данных переписи населения
test_population = [randint(AGE_MIN, AGE_MAX) for i in range(0, POPULATION)]
#print("Исходные данные переписи населения:\n", test_population)

# счётчики возраста запишем в словарь. ключ словаря - возраст, значение - кол-во людей
age_stats = {}
for person in range(len(test_population)):
	try:
		age_stats[test_population[person]] += 1
	except:
		age_stats[test_population[person]] = 1
print("\nСтатистика населения по возрастам:\n", age_stats)

# создадим отсортированный массив данных о возрастах
age_sorted = []
print("\nСортируем данные переписи:")
for age in range(AGE_MIN, AGE_MAX + 1):
#	print(age, ": ", [age] * age_stats[age])
	age_sorted.extend([age] * age_stats[age])
print("Размер отсортированного списка =", "{:,d}".format(len(age_sorted)))
#print(age_sorted)
