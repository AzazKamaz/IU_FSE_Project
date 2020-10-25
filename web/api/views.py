import jwt
import json
from django.conf import settings
from django.db import transaction
from django.http import HttpResponse
from django.shortcuts import render

from api.models import Person, Lesson, Attendance


def jwt_payload(func):
    def process(request, *args, **kwargs):
        if 'jwt' not in request.GET:
            return HttpResponse("Missing required field jwt", status=403)

        token = request.GET['jwt']

        try:
            payload = jwt.decode(token, verify=False)
            user, _ = Person.objects.update_or_create(id=payload['oid'], defaults={
                'name': payload['name'],
                'email': payload.get('email', None) or payload.get('unique_name', '')
            })
        except jwt.PyJWTError:
            return HttpResponse("Invalid jwt token", status=403)

        return func(request, *args, user=user, **kwargs)

    return process


@transaction.atomic
@jwt_payload
def authorize(request, user):
    return HttpResponse("OK")


@transaction.atomic
@jwt_payload
def attend(request, user):
    for field in ['student', 'lesson']:
        if field not in request.GET:
            return HttpResponse(f"Missing required parameter {field}", status=400)

    lesson, _ = Lesson.objects.get_or_create(
        lesson_id=request.GET['lesson'],
        teacher=user
    )
    try:
        student = Person.objects.get(id=request.GET['student'])
    except Person.DoesNotExist:
        return HttpResponse("Such student doesn't exist", status=400)

    Attendance.objects.create(person=student, lesson=lesson)

    return HttpResponse(json.dumps({
        'id': student.id,
        'name': student.name,
        'email': student.email
    }))


@transaction.atomic
@jwt_payload
def get_attendance(request, user):
    if 'lesson' not in request.GET:
        return HttpResponse("Missing required parameter lesson")

    lesson = Lesson.objects.get(
        lesson_id=request.GET['lesson'],
        teacher=user
    )

    return HttpResponse(json.dumps(
        [{'id': attendance.person.id, 'email': attendance.person.email, 'name': attendance.person.name} for attendance
         in
         lesson.attendance.all()]))
