# Tests for dittoPlot function
# library(dittoSeq); library(testthat); source("setup.R"); source("test-FreqPlot.R")

sce1 <- sce
colnames(sce1) <- paste0(colnames(sce1),"_1")
# sce <- cbind(sce, sce1)
sce <- setBulk(
    importDittoBulk(
        x = list(counts = cbind(
            SummarizedExperiment::assay(sce, 1),
            SummarizedExperiment::assay(sce1, 1)
        )),
        metadata = rbind(
            colData(sce),
            colData(sce1)
        )
    ),
    FALSE)

sce$number <- as.numeric(seq_along(colnames(sce)))
sce$sample <- rep(1:15, each = 10)
sce$groups <- c(rep("A", 80), rep("B", 70))
sce$subgroups <- rep(as.character(c(1:5,1:5,1:5)), each = 10)

sce$clusters <- factor(sce$clusters, levels = 1:4)

grp1 <- "clusters"
grp2 <- "sample"
grp3 <- "groups"
grp4 <- "subgroups"
bad_grp <- "age"
cells.names <- colnames(sce)[1:40]
cells.logical <- c(rep(TRUE, 40), rep(FALSE,ncol(sce)-40))

# Function relies on combination of machinery of dittoPlot & dittoBarPlot, so
# tests here just need to address unique pieces.

test_that("dittoFreqPlot can quantify values in percent or raw count", {
    # MANUAL: ymax <= 1
    expect_s3_class(
        dittoFreqPlot(
            sce, grp1, sample.by = grp2, group.by = grp3, color.by = grp4),
        "ggplot")
    # MANUAL: ymax >= 1
    expect_s3_class(
        dittoFreqPlot(
            sce, grp1, sample.by = grp2, group.by = grp3, color.by = grp4,
            scale = "count"),
        "ggplot")
})

test_that("dittoFreqPlot makes sample alteration for bulk", {
    # MANUAL: should refer to samples, not cells
    expect_s3_class(
        dittoFreqPlot(
            setBulk(sce), grp1, sample.by = grp2, group.by = grp3),
        "ggplot")
})

test_that("dittoFreqPlots can be subset to show only certain cells/samples with any cells.use method", {
    expect_s3_class(
        {p1 <- dittoFreqPlot(
            sce, grp1, sample.by = grp2, group.by = grp3,  data.out = TRUE,
            cells.use = cells.names)
        p1$p},
        "ggplot")
    expect_s3_class(
        {p2 <- dittoFreqPlot(
            sce, grp1, sample.by = grp2, group.by = grp3, data.out = TRUE,
            cells.use = cells.logical)
        p2$p},
        "ggplot")
    expect_equal(p1$data, p2$data)
    expect_s3_class(
        {p3 <- dittoFreqPlot(
            sce, grp1, sample.by = grp2, group.by = grp3, data.out = TRUE,
            cells.use = 1:40)
        p3$p},
        "ggplot")
    expect_equal(p1$data, p3$data)
    
    # And if we remove an entire X grouping...
    expect_s3_class(
        dittoFreqPlot(
            sce, grp1, sample.by = grp2, group.by = grp3,
            cells.use = meta(grp3,sce)!=0),
        "ggplot")
    # And if we remove an entire var grouping...
    expect_s3_class(
        dittoFreqPlot(
            sce, grp1, sample.by = grp2, group.by = grp3,
            cells.use = meta(grp1,sce)!=4),
        "ggplot")
})

test_that("dittoFreqPlot can trim to individual var-values with vars.use", {
    # MANUAL: single facet
    expect_s3_class(
        dittoFreqPlot(
            setBulk(sce), grp1, sample.by = grp2, group.by = grp3,
            vars.use = 1),
        "ggplot")
    
    # MANUAL: should only be two facets
    expect_s3_class(
        dittoFreqPlot(
            setBulk(sce), grp1, sample.by = grp2, group.by = grp3,
            vars.use = 1:2),
        "ggplot")
    
    # MANUAL: Two facets, "A" & "B", same look otherwise as above
    expect_s3_class(
        dittoFreqPlot(
            setBulk(sce), grp1, sample.by = grp2, group.by = grp3,
            vars.use = c("A","B"),
            var.labels.rename = c("A","B","C","D")),
        "ggplot")
})

test_that("dittoFreqPlot can max.normalize the data", {
    # MANUAL: should refer to samples, not cells
    expect_s3_class(
        {p <- dittoFreqPlot(
            setBulk(sce), grp1, sample.by = grp2, group.by = grp3,
            data.out = TRUE,
            max.normalize = TRUE)
            p$p},
        "ggplot")
    expect_true(all(
        c("count.norm", "percent.norm") %in% colnames(p$data)
        ))
})

test_that("dittoFreqPlot properly checks if samples vs grouping-data has mismatches", {
    expect_error(
        dittoFreqPlot(
            sce, grp1, sample.by = grp2, group.by = bad_grp),
        "Unable to interpret 'group.by' with 'samples.by'. 'age' data does not map 1:1 per sample.", fixed = TRUE)
    expect_error(
        dittoFreqPlot(
            sce, grp1, sample.by = grp2, group.by = grp3,
            color.by = bad_grp),
        "Unable to interpret 'color.by' with 'samples.by'. 'age' data does not map 1:1 per sample.", fixed = TRUE)
    
    # No error if no sample.by given
    expect_s3_class(
        dittoFreqPlot(
            setBulk(sce), grp1, group.by = grp3,
            color.by = bad_grp),
        "ggplot")
})

test_that("dittoFreqPlot, 'retain.factor.level' can be used to respect factor levels", {
    sce$var_factor <- factor(
        meta(grp1, sce),
        levels = rev(metaLevels(grp1, sce)))
    sce$grp_factor <- factor(
        meta(grp3, sce),
        levels = rev(metaLevels(grp3, sce)))
    
    # MANUAL: var and group.by ordering should be reverse of alpha-numeric
    #  & group.by-A should remain but be all zero.
    expect_s3_class(
        dittoFreqPlot(
            sce, "var_factor", sample.by = grp2, group.by = "grp_factor",
            retain.factor.levels = TRUE,
            cells.use = meta("grp_factor",sce)!="A"),
        "ggplot")
})
