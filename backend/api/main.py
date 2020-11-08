from fastapi import FastAPI, Request, Header
from fastapi.responses import JSONResponse
from .db import *
import json, base64, re

app = FastAPI()


def b64decode(data, altchars=b'+/'):
    """Decode base64, padding being optional.

    :param data: Base64 data as an ASCII byte string
    :returns: The decoded byte string.

    """
    data = re.sub(r'[^a-zA-Z0-9%s]+' % altchars, '', data)  # normalize
    missing_padding = len(data) % 4
    if missing_padding:
        data += '='* (4 - missing_padding)
    return base64.b64decode(data, altchars)


auth = lambda jwt: json.loads(b64decode(jwt.split('.')[1]))


@app.exception_handler(Exception)
async def unicorn_exception_handler(request: Request, e: Exception):
    return JSONResponse(
        status_code=400,
        content={"message": str(e)},
    )


@app.post("/ensureUser")
async def ensureUser(authorization: str = Header(None)):
    user = auth(authorization)
    await db.updateUser(user["oid"], user["name"], user["email"])
    return {
        "success" : True
    }


@app.post("/attend")
async def attendHandler(request: Request, authorization: str = Header(None)):
    data = await request.json()
    user = auth(authorization)
    await db.updateAttendance(data["input"]["class_id"], data["input"]["user_id"])
    return {
        "success" : True
    }