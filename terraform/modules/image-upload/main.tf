# Upload VM image or LXC template to Proxmox using the provider's file upload resource
locals {
  # Determine final image path
  final_image_path = var.local_image_path != null ? var.local_image_path : (
    var.instance_name != null && length(data.external.find_image) > 0 ? data.external.find_image[0].result.path : null
  )

  image_name = local.final_image_path != null ? basename(local.final_image_path) : null

  # Determine content type and datastore based on image type
  # LXC templates use "vztmpl", VM backups use "backup"
  # For vma.zst files (VM backups), use content_type "backup"
  content_type = var.image_type == "vm" ? "backup" : "vztmpl"
  datastore_id = var.storage
}

# Find the actual image file (handles wildcards in path)
data "external" "find_image" {
  count = var.local_image_path == null && var.instance_name != null ? 1 : 0

  program = ["bash", "-c", <<-EOT
    set -e
    # Resolve workspace root to absolute path
    cd "${var.workspace_root}"
    WORKSPACE_ROOT="$(pwd)"
    INSTANCE_NAME="${var.instance_name}"
    IMAGE_TYPE="${var.image_type}"
    
    # Construct search pattern
    if [ "$IMAGE_TYPE" = "vm" ]; then
      SEARCH_DIR="$WORKSPACE_ROOT/results/$INSTANCE_NAME/result"
      PATTERN="*.vma.zst"
      CMD_TYPE="image"
    else
      SEARCH_DIR="$WORKSPACE_ROOT/results/$INSTANCE_NAME/result/tarball"
      PATTERN="*.tar.xz"
      CMD_TYPE="image-container"
    fi
    
    # Check if directory exists
    if [ ! -d "$SEARCH_DIR" ]; then
      echo "{\"error\": \"Directory not found: $SEARCH_DIR. Run 'just $CMD_TYPE $INSTANCE_NAME' first\"}" >&2
      exit 1
    fi
    
    # Find first matching file
    FOUND=$(ls -1 "$SEARCH_DIR"/$PATTERN 2>/dev/null | head -n1 || echo "")
    
    if [ -z "$FOUND" ]; then
      echo "{\"error\": \"No image found in $SEARCH_DIR matching $PATTERN. Run 'just $CMD_TYPE $INSTANCE_NAME' first\"}" >&2
      exit 1
    fi
    
    echo "{\"path\": \"$FOUND\"}"
  EOT
  ]
}

# Upload file using the provider's file upload resource
resource "proxmox_virtual_environment_file" "image" {
  count = local.final_image_path != null ? 1 : 0

  node_name    = var.node_name
  datastore_id = local.datastore_id
  content_type = local.content_type
  source_file {
    path = local.final_image_path
  }
}

# For VM images (vma.zst), return the file ID for use with VM restore
# For LXC templates (tar.xz), return the file ID for use as template_file_id
output "file_id" {
  description = "File identifier from Proxmox (file_id attribute)"
  value       = local.final_image_path != null ? proxmox_virtual_environment_file.image[0].id : null
}

output "file_name" {
  description = "Uploaded file name"
  value       = local.image_name
}

output "local_image_path" {
  description = "Local path to the image file that was uploaded"
  value       = local.final_image_path
}
