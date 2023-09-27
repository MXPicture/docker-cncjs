variable "CI" { default = "true" }
target "default" {
    no-cache   = "true"
    tags       = ["mxpicture/cncjs:latest"]
    dockerfile = "Dockerfile"
    context    = "."
    output     = [equal(CI, "true") ? "type=registry": "type=docker"]
    platforms  = equal(CI, "true") ? ["linux/amd64", "linux/arm64", "linux/arm"] : []
}