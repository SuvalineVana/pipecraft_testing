#!/usr/bin/env Rscript

#DADA2 sequence classifier.

#load dada2
library("dada2")

#load env variables
readType = Sys.getenv('readType')
fileFormat = Sys.getenv('fileFormat')
dataFormat = Sys.getenv('dataFormat')
workingDir = Sys.getenv('workingDir')

#check for output dir and delete if needed
if (dir.exists("/input/taxonomy_out.dada2")) {
    unlink("/input/taxonomy_out.dada2", recursive=TRUE)
}
#create output dir
path_results = "/input/taxonomy_out.dada2"
dir.create(path_results)

#load environment variables
database = Sys.getenv('dada2_database')
database = gsub("\\\\", "/", database) #replace backslashes \ in the database path
database = paste("/extraFiles", basename(database), sep = "/")
minBoot = as.integer(Sys.getenv('minBoot'))
tryRC = Sys.getenv('tryRC')
print(database)
print(workingDir)

#"FALSE" or "TRUE" to FALSE or TRUE for dada2
if (tryRC == "false" || tryRC == "FALSE"){
    tryRC = FALSE
}
if (tryRC == "true" || tryRC == "TRUE"){
    tryRC = TRUE
}

#load data
ASVs_fasta = readRDS(file.path(workingDir, "ASVs.fasta"))

#assign taxonomy
tax = assignTaxonomy(ASVs_fasta, database, multithread = FALSE, minBoot = minBoot, tryRC = tryRC, outputBootstraps = TRUE)

###format and save taxonomy results
#sequence headers
asv_headers = vector(dim(ASVs_fasta)[2], mode="character")
for (i in 1:dim(ASVs_fasta)[2]) {
asv_headers[i] = paste(">ASV", i, sep="_")
}
#add sequences to 1st column
tax2 = cbind(row.names(tax$tax), tax$tax, tax$boot)
colnames(tax2)[1] = "Sequence"
#row names as sequence headers
row.names(tax2) = sub(">", "", asv_headers)

#write taxonomy to csv
write.table(tax2, file.path(path_results, "taxonomy.csv"), sep = "\t", quote=F, col.names = NA)

#DONE

print('workingDir=/input/taxonomy_out.dada2')
print('fileFormat=taxtab')
print('dataFormat=demultiplexed')
print('readType=single_end')
