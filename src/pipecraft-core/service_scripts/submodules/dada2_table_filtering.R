#!/usr/bin/env Rscript

#Filter DADA2 ASV table; collapse no mismatch and/or filer by ASV length

#load variables
table_rds = Sys.getenv('DADA2_table')
table_rds = paste0("/extraFiles/", basename(table_rds))

collapseNoMismatch = Sys.getenv('collapseNoMismatch')
minOverlap = as.numeric(Sys.getenv('minOverlap'))
vec = Sys.getenv('vec')
len_filt = as.numeric(Sys.getenv('by_length'))

#print variables
print(table_rds)
print(collapseNoMismatch)
print(minOverlap)
print(vec)
print(len_filt)

#ASV table path
path_ASVs="/input/ASVs_filt.out.dada2"

#load dada2
library('dada2')
print("### Filtering the ASV table")
print("")

##########################################
#Combine together sequences that are identical up to shifts and/or length.
if (collapseNoMismatch == "true") {
    print("Combining together ASVs that are identical")
    
    # Load ASVs table from the DADA2 workflow
    table_in = readRDS(table_rds)

    ASV_tab_collapsed = collapseNoMismatch(table_in, minOverlap = minOverlap, vec = vec)
    saveRDS(ASV_tab_collapsed, file.path(path_ASVs, "ASV_tab_collapsed.rds"))

    #Print ASV count
    print(paste0("total no. of input ASVs = ", dim(table_in)[2]))
    print(paste0("no. of ASVs in a collapsed table = ", dim(ASV_tab_collapsed)[2]))
    print("")

    ###format and save ASV table and ASVs.fasta
    #sequence headers
    asv_seqs = colnames(ASV_tab_collapsed)
    asv_size = colSums(ASV_tab_collapsed)
    asv_headers = vector(dim(ASV_tab_collapsed)[2], mode="character")
    for (i in 1:dim(ASV_tab_collapsed)[2]) {
        asv_headers[i] = paste(">ASV", i, ";size=", asv_size[i], sep="")
    }
    #transpose sequence table
    tASV_tab_collapsed = t(ASV_tab_collapsed)
    #add sequences to 1st column
    tASV_tab_collapsed = cbind(row.names(tASV_tab_collapsed), tASV_tab_collapsed)
    colnames(tASV_tab_collapsed)[1] = "Sequence"
    #row names as sequence headers
    row.names(tASV_tab_collapsed) = sub(">", "", asv_headers)
    #write ASVs.fasta to path_ASVs
    asv_fasta <- c(rbind(asv_headers, asv_seqs))
    write(asv_fasta, file.path(path_ASVs, "ASVs_collapsed.fasta"))
    #write ASVs table to path_ASVs
    write.table(tASV_tab_collapsed, file.path(path_ASVs, "ASVs_table_collapsed.txt"), sep = "\t", col.names = NA, row.names = TRUE, quote = FALSE)

    #input for length filtering, if != 0
    table_in = ASV_tab_collapsed

    #remove datasets from the environment
    rm(tASV_tab_collapsed)
    rm(asv_seqs)
    rm(asv_headers)
    rm(asv_fasta)
}


##########################################

##########################################
# Filter ASVs based on length
if (collapseNoMismatch != "true") {
    table_in = readRDS(table_rds)
}

if (len_filt != 0) {
    print(paste0("Filtering ASVs by length; discarding ASVs with sequence length < ", len_filt))
    a = c()
    short_ASV_count = 0
    for (i in 1:dim(table_in)[2]) {
        #if len < len_filt 
        x = as.numeric(nchar(colnames(table_in)[i])) #ASV seq len
        if (x < len_filt) {
            a = append(a, i)
            short_ASV_count = short_ASV_count + 1 
        }
    }
    ASV_tab_lenFilt = table_in[,-c(a)] #remove columns, i.e ASVs with short seqs

    #print ASV count
    print(paste0("< ", len_filt, " bp ASVs = ", short_ASV_count))
    print(paste0("no. of ASVs in a length filtered table = ", dim(ASV_tab_lenFilt)[2]))
    print("")

    ###format and save ASV table and ASVs.fasta
    #sequence headers with size
    asv_seqs = colnames(ASV_tab_lenFilt)
    asv_size = colSums(ASV_tab_lenFilt)
    asv_headers = vector(dim(ASV_tab_lenFilt)[2], mode="character")
    for (i in 1:dim(ASV_tab_lenFilt)[2]) {
        asv_headers[i] = paste(">ASV", i, ";size=", asv_size[i], sep="")
    }
    #transpose sequence table
    tASV_tab_lenFilt = t(ASV_tab_lenFilt)
    #add sequences to 1st column
    tASV_tab_lenFilt = cbind(row.names(tASV_tab_lenFilt), tASV_tab_lenFilt)
    colnames(tASV_tab_lenFilt)[1] = "Sequence"
    #row names as sequence headers
    row.names(tASV_tab_lenFilt) = sub(">", "", asv_headers)

    #write ASVs.fasta to path_ASVs
    asv_fasta <- c(rbind(asv_headers, asv_seqs))
    write(asv_fasta, file.path(path_ASVs, "ASVs_lenFilt.fasta"))
    #write ASVs table to path_ASVs
    write.table(tASV_tab_lenFilt, file.path(path_ASVs, "ASV_table_lenFilt.txt"), sep = "\t", col.names = NA, row.names = TRUE, quote = FALSE)
}
##########################################

#DONE 

