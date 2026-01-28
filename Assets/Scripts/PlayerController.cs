using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
public class PlayerController : MonoBehaviour
{
    public Transform cameraPivot;

    [Header("Movement")]
    public float moveSpeed = 5f;
    public float gravity = -9.81f;
    public float jumpHeight = 1.2f; 

    [Header("Mouse Look")]
    public float mouseSensitivity = 0.1f;
    public float maxLookAngle = 80f;

    CharacterController controller;
    PlayerInputActions input;

    float verticalVelocity;
    float pitch;

    void Awake()
    {
        controller = GetComponent<CharacterController>();
        input = new PlayerInputActions();
    }

    void OnEnable()
    {
        input.Player.Enable();
    }

    void OnDisable()
    {
        input.Player.Disable();
    }

    void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    void Update()
    {
        HandleMouseLook();
        HandleMovement();
    }

    void HandleMovement()
    {
        Vector2 moveInput = input.Player.Move.ReadValue<Vector2>();

        Vector3 moveDirection = transform.right * moveInput.x + transform.forward * moveInput.y;

        if (controller.isGrounded && verticalVelocity < 0f)
        {
            verticalVelocity = -2f;
        }

        if (input.Player.Jump.triggered && controller.isGrounded)
        {
            verticalVelocity = Mathf.Sqrt(jumpHeight * -2f * gravity);
        }

        verticalVelocity += gravity * Time.deltaTime;

        Vector3 finalVelocity = moveDirection * moveSpeed;
        finalVelocity.y = verticalVelocity;
        controller.Move(finalVelocity * Time.deltaTime);
    }

    void HandleMouseLook()
    {
        Vector2 look = input.Player.Look.ReadValue<Vector2>();

        float mouseX = look.x * mouseSensitivity;
        float mouseY = look.y * mouseSensitivity;

        transform.Rotate(Vector3.up * mouseX);

        pitch -= mouseY;
        pitch = Mathf.Clamp(pitch, -maxLookAngle, maxLookAngle);
        cameraPivot.localRotation = Quaternion.Euler(pitch, 0, 0);
    }
}
