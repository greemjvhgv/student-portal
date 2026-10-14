

from fastapi import HTTPException, status


def require_authenticated_student():
    """
    Temporary security dependency.

    Blocks access until the group's authentication
    implementation is available.
    """
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Student authentication is not yet available."
    )
