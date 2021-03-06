#' import bulk sequencing data into a SingleCellExperiment format that will work with other dittoSeq functions.
#' @param x A \code{DGEList}, or \code{\linkS4class{SummarizedExperiment}} (includes \code{DESeqDataSet}) class object containing the sequencing data to be imported.
#' 
#' Alternatively, for import from a raw matrix format, a named list of matrices (or matrix-like objects) where names will become the assay names of the eventual SCE.
#' 
#' NOTE: As of dittoSeq version 1.1.11, all dittoSeq functions can work directly with SummarizedExperiment objects, so this import function is nolonger required for such data.
#' @param reductions A named list of dimensionality reduction embeddings matrices.
#' Names will become the names of the dimensionality reductions and how each will be used with the \code{reduction.use} input of \code{dittoDimPlot} and \code{dittoDimHex}.
#' 
#' For each matrix, rows of the matrices should represent the different samples of the dataset, and columns the different dimensions.
#' @param metadata A data.frame (or data.frame-like object) where rows represent samples and named columns represent the extra information about such samples that should be accessible to visualizations.
#' The names of these columns can then be used to retrieve and plot such data in any dittoSeq visualization.
#' @param combine_metadata Logical which sets whether original \code{colData} (DESeqDataSet/SummarizedExperiment) or \code{$samples} (DGEList) from \code{x} should be retained.
#' 
#' When \code{x} is a SummarizedExperiment or DGEList:
#' \itemize{
#' \item When \code{FALSE}, sample metadata inside \code{x} (colData or $samples) is ignored entirely.
#' \item When \code{TRUE} (the default), metadata inside \code{x} is combined with what is provided to the \code{metadata} input; but names must be unique, so when there are similarly named slots, the \strong{values provided to the \code{metadata} input take priority.}
#' }
#' @return A \code{\linkS4class{SingleCellExperiment}} object...
#' 
#' that contains all assays (SummarizedExperiment; includes DESeqDataSets), all standard slots (DGEList; see below for specifics), or expression matrices of the input \code{x},
#' as well as any dimensionality reductions provided to \code{reductions}, and any provided \code{metadata} stored in colData.
#'
#' @section Note about SummarizedExperiments: As of dittoSeq version 1.1.11, all dittoSeq functions can work directly with SummarizedExperiment objects, so this import function is nolonger required for such data.
#' 
#' @seealso \code{\linkS4class{SingleCellExperiment}} for more information about this storage structure.
#'
#' @section Note on assay names:
#' One recommended assay to create if it is not already present in your dataset, is a log-normalized version of the counts data.
#' The logNormCounts function of the scater package is an easy way to make such a slot.
#' 
#' dittoSeq visualizations default to grabbing expression data from an assay named logcounts > normcounts > counts
#'
#' @examples
#' library(SingleCellExperiment)
#'
#' # Generate some random data
#' nsamples <- 60
#' exp <- matrix(rpois(1000*nsamples, 20), ncol=nsamples)
#' colnames(exp) <- paste0("sample", seq_len(ncol(exp)))
#' rownames(exp) <- paste0("gene", seq_len(nrow(exp)))
#' logexp <- log2(exp + 1)
#'
#' # Dimensionality Reductions
#' pca <- matrix(runif(nsamples*5,-2,2), nsamples)
#' tsne <- matrix(rnorm(nsamples*2), nsamples)
#'
#' # Some Metadata
#' conds <- factor(rep(c("condition1", "condition2"), each=nsamples/2))
#' timept <- rep(c("d0", "d3", "d6", "d9"), each = 15)
#' genome <- rep(c(rep(TRUE,7),rep(FALSE,8)), 4)
#' grps <- sample(c("A","B","C","D"), nsamples, TRUE)
#' clusts <- as.character(1*(tsne[,1]>0&tsne[,2]>0) +
#'                        2*(tsne[,1]<0&tsne[,2]>0) +
#'                        3*(tsne[,1]>0&tsne[,2]<0) +
#'                        4*(tsne[,1]<0&tsne[,2]<0))
#' score1 <- seq_len(nsamples)/2
#' score2 <- rnorm(nsamples)
#'
#' ### We can import the counts directly
#' myRNA <- importDittoBulk(
#'     x = list(counts = exp,
#'          logcounts = logexp))
#'
#' ### Adding metadata & PCA or other dimensionality reductions
#' # We can add these directly during import, or after.
#' myRNA <- importDittoBulk(
#'     x = list(counts = exp,
#'         logcounts = logexp),
#'     metadata = data.frame(
#'         conditions = conds,
#'         timepoint = timept,
#'         SNP = genome,
#'         groups = grps),
#'     reductions = list(
#'         pca = pca))
#'
#' myRNA$clustering <- clusts
#'
#' myRNA <- addDimReduction(
#'     myRNA,
#'     embeddings = tsne,
#'     name = "tsne")
#'
#' # (other packages SCE manipulations can also be used)
#'
#' ### When we import from SummarizedExperiment, all metadata is retained.
#' # The object is just 'upgraded' to hold extra slots.
#' # The output is the same, aside from a message when metadata are replaced.
#' se <- SummarizedExperiment(
#'     list(counts = exp, logcounts = logexp))
#' myRNA <- importDittoBulk(
#'     x = se,
#'     metadata = data.frame(
#'         conditions = conds,
#'         timepoint = timept,
#'         SNP = genome,
#'         groups = grps,
#'         clustering = clusts,
#'         score1 = score1,
#'         score2 = score2),
#'     reductions = list(
#'         pca = pca,
#'         tsne = tsne))
#' myRNA
#'
#' ### For DESeq2, how we might have made this:
#' # DESeqDataSets are SummarizedExperiments, and behave similarly
#' # library(DESeq2)
#' # dds <- DESeqDataSetFromMatrix(
#' #     exp, data.frame(conditions), ~ conditions)
#' # dds <- DESeq(dds)
#' # dds_ditto <- importDittoBulk(dds)
#'
#' ### For edgeR, DGELists are a separate beast.
#' # dittoSeq imports what I know to commonly be inside them, but please submit
#' # an issue on the github (dtm2451/dittoSeq) if more should be retained.
#' # library(edgeR)
#' # dgelist <- DGEList(counts=exp, group=conditions)
#' # dge_ditto <- importDittoBulk(dgelist)
#'
#' @importClassesFrom SingleCellExperiment SingleCellExperiment
#' @importClassesFrom SummarizedExperiment SummarizedExperiment
#' @importFrom methods is as
#' @importFrom SummarizedExperiment SummarizedExperiment "colData<-" colData rowData
#' @importFrom utils packageVersion
#' @importFrom SingleCellExperiment "int_metadata<-" int_metadata "reducedDim<-"
#' @importFrom S4Vectors DataFrame
#' @export

importDittoBulk <- function(
    x, reductions = NULL, metadata = NULL, combine_metadata = TRUE) {

    # Turn x into a SummarizedExperiment
    if (is(x, "DGEList")) {
        x <- .creat_SE_from_DGEList(x, reductions, metadata, combine_metadata)
    }
    if (is(x, "list")) {
        x <- .create_SE_from_raw(x, reductions, metadata)
        # Ignore this input:
        combine_metadata <- TRUE
    }
    
    # Convert from SE to SCE
    object <- as(x, "SingleCellExperiment")
    
    # Use SCE int_metadata to store dittoSeq version and that dataset is bulk
    SingleCellExperiment::int_metadata(object) <- c(
        SingleCellExperiment::int_metadata(object),
        dittoSeqVersion = packageVersion("dittoSeq"),
        bulk = TRUE)

    # Add metadata
    if (!is.null(metadata)) {
        if (combine_metadata) {
            # Add metadata from `x` to provided `metadata` dataframe.
            obj_metadata <- SummarizedExperiment::colData(object)
            dups <- colnames(obj_metadata) %in% colnames(metadata)
            # If any names are repeated, use from the provided `metadata`
            if (any(dups)) {
                message(
                    paste(colnames(obj_metadata)[dups], collapse = ", "),
                    " metadata originally within 'x' was overwitten from provided 'metadata'")
            }
            metadata <- cbind(obj_metadata[,!dups, drop = FALSE], metadata)
        }
        SummarizedExperiment::colData(object) <- S4Vectors::DataFrame(metadata)
    }

    # Add reductions
    if (!is.null(reductions)) {
        if (is.null(names(reductions))) {
            stop("Elements of 'reductions' must be named to be added.")
        }
        for (i in names(reductions)) {
            if (i == "") stop("All elements of 'reductions' must be named.")
            object <- addDimReduction(object,reductions[[i]],i)
        }
    }
    
    object
}

.creat_SE_from_DGEList <- function(
    x, reductions = NULL, metadata = NULL, combine_metadata = TRUE) {

    ### Convert DGEList to Summarized Experiment while preserving as many
    ### optional slots as possible
    
    # Grab essential slots
    args <- list(
        assays = list(counts=x$counts),
        colData = data.frame(x$samples))
    
    # Add optional rowData
    rowData <- list()
    add_if_slot <- function(i, out = rowData) {
        if (!is.null(x[[i]])) {
            out <- c(out, list(x[[i]]))
            names(out)[length(out)] <- i
        }
        out
    }
    rowData <- add_if_slot("genes")
    rowData <- add_if_slot("AveLogCPM")
    rowData <- add_if_slot("common.dispersion")
    rowData <- add_if_slot("trended.dispersion")
    rowData <- add_if_slot("tagwise.dispersion")
    if (length(rowData)>0) {
        args$rowData <- data.frame(rowData)
    }
    
    # Add optional assay: offset
    if (!is.null(x$offset)) {
        args$assays <- list(counts = x$counts,
                            offset = x$offset)
    }
    
    # Make SE
    do.call(SummarizedExperiment::SummarizedExperiment, args)
}

.create_SE_from_raw <- function(x, reductions = NULL, metadata = NULL) {

    # Check that the elements of x are named matrices with equal ncols
    ncol1 <- ncol(x[[1]])
    ncol.same <- all(vapply(
        seq_along(x),
        function (ind) {ncol(x[[ind]])==ncol1},
        FUN.VALUE = logical(1)))
    if (is.null(names(x)) || !ncol.same) {
        stop("Elements of 'x' should be named and should all have the same number of columns.")
    }

    # Create SummarizedExperiment
    SummarizedExperiment::SummarizedExperiment(assays = x)
}
