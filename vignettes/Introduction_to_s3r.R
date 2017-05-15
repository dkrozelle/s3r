## ---- eval=FALSE---------------------------------------------------------
# s3_set(bucket = "s3r-test-bucket", profile = "s3r-read-write-user")
# s3_ls()
# 
# df <- data.frame(col1 = c(1,2,3), col2=c(2,3,4))
# s3_put_with(df, write.csv, "file.csv")
# s3_ls()
# 
# s3_put_s3(from = "note.txt", to = list("top", "next", "third", "fourth", "filename.txt"))
# s3_put_s3(from = "note.txt", to = list("top", "next", "third", "filename2.txt"))
# s3_ls("top", "next", recursive = T)
# 
# build_uri("top", "next", "third")


