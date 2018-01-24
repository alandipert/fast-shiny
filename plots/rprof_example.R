data("mtcars")
plot(mpg ~ hp, data = mtcars)
m <- lm(mpg ~ hp, data = mtcars)
abline(m, col = "red")

