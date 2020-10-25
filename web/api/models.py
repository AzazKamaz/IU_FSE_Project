from django.db import models


class Person(models.Model):
    id = models.CharField(max_length=64, primary_key=True)
    email = models.CharField(max_length=255, db_index=True)
    name = models.CharField(max_length=255)


class Lesson(models.Model):
    teacher = models.ForeignKey(Person, on_delete=models.CASCADE, related_name='my_lessons')
    lesson_id = models.CharField(max_length=255, db_index=True)
    attended = models.ManyToManyField(Person, through='Attendance', related_name='lessons')


class Attendance(models.Model):
    person = models.ForeignKey(Person, on_delete=models.CASCADE, related_name='attendance')
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='attendance')
    created = models.DateTimeField(auto_now_add=True)
