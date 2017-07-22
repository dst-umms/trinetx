#!/usr/bin/env Rscript
#vim: syntax=r tabstop=2 expandtab

library(ggplot2)
library(reshape2)
library(scales)

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1], header = TRUE, row.names = 1, sep = ",")

x <- data.frame(Gene = rownames(data),
                TriNetX = as.numeric(as.matrix(data[,"TriNetX_Count"])), 
                MolDx = as.numeric(as.matrix(data[,"MolDx_Count"])))

x1 <- melt(x, id.var="Gene")

png(args[2], width = 8, height = 8, unit = "in", res = 300)
upper_limit <- max(x$MolDx)
limits <- seq(0, upper_limit, length.out = 10)
limits <- round(limits/10) * 10

colors <- c(MolDx="steelblue1", TriNetX="steelblue4")

q <- ggplot(x1, aes(x = Gene, y = value, fill = variable)) + geom_bar(stat = "identity", position = "dodge") 
q + scale_y_continuous("", limits = c(0, upper_limit), breaks = limits) +
scale_fill_manual(values = colors) + labs(title = "TriNetX Vs MolDx - Gene Level Counts\n\n", x = "Gene Names", y = "") +
guides(fill = guide_legend(title = NULL)) + theme_bw() + theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5, size = 10))

dev.off()
