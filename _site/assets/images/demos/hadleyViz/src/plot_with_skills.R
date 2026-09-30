library(httr2)
library(jsonlite)
library(dplyr)
library(purrr)
library(stringr)
library(tibble)
library(ggplot2)
library(ggrepel)

gene <- "TP53"
transcript_of_interest <- "NM_000546.6"

query <- paste0(
  gene,
  '[gene] AND "reviewed by expert panel"[review status] AND single_gene[prop]'
)

eutils_base <- "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

output_file <- "../output/tp53_clinvar_expert_with_HadleyViz_skill.png"

# -------------------------------------------------------------------------
# NCBI E-utilities
# -------------------------------------------------------------------------

ncbi_get_json <- local({
  last_request <- NULL
  
  function(endpoint, ...) {
    if (!is.null(last_request)) {
      elapsed <- as.numeric(
        difftime(Sys.time(), last_request, units = "secs")
      )
      
      if (elapsed < 0.4) {
        Sys.sleep(0.4 - elapsed)
      }
    }
    
    response <- request(paste0(eutils_base, "/", endpoint)) |>
      req_url_query(
        db = "clinvar",
        retmode = "json",
        ...
      ) |>
      req_user_agent("TP53-ClinVar-conference-plot/1.0") |>
      req_retry(max_tries = 5) |>
      req_perform()
    
    last_request <<- Sys.time()
    
    resp_check_status(response)
    resp_body_json(response, simplifyVector = FALSE)
  }
})

# -------------------------------------------------------------------------
# 1. Get total record count
# -------------------------------------------------------------------------

search_count <- ncbi_get_json(
  "esearch.fcgi",
  term = query,
  retmax = 0
)

total_count <- as.integer(search_count$esearchresult$count)

if (is.na(total_count) || total_count < 1L) {
  stop("The ClinVar query returned no records.")
}

# -------------------------------------------------------------------------
# 2. Retrieve all ClinVar IDs in pages
# -------------------------------------------------------------------------

page_size <- 1000L

retstarts <- seq.int(
  from = 0L,
  to = total_count - 1L,
  by = page_size
)

id_pages <- map(
  retstarts,
  function(retstart) {
    result <- ncbi_get_json(
      "esearch.fcgi",
      term = query,
      retstart = retstart,
      retmax = min(page_size, total_count - retstart)
    )
    
    as.character(
      unlist(result$esearchresult$idlist, use.names = FALSE)
    )
  }
)

clinvar_ids <- unique(unlist(id_pages, use.names = FALSE))

if (length(clinvar_ids) != total_count) {
  stop(
    "Expected ",
    total_count,
    " ClinVar IDs but retrieved ",
    length(clinvar_ids),
    ". Aborting rather than plotting an incomplete result set."
  )
}

# -------------------------------------------------------------------------
# 3. Retrieve ESummary records in batches
# -------------------------------------------------------------------------

summary_batch_size <- 100L

id_batches <- split(
  clinvar_ids,
  ceiling(seq_along(clinvar_ids) / summary_batch_size)
)

summary_batches <- map(
  id_batches,
  function(ids) {
    ncbi_get_json(
      "esummary.fcgi",
      id = paste(ids, collapse = ",")
    )
  }
)

summary_docs <- map(
  summary_batches,
  function(result) {
    uids <- as.character(
      unlist(result$result$uids, use.names = FALSE)
    )
    
    docs <- lapply(
      uids,
      function(uid) result$result[[uid]]
    )
    
    names(docs) <- uids
    docs
  }
) |>
  unlist(recursive = FALSE)

# -------------------------------------------------------------------------
# Helpers for conservative extraction from ClinVar summaries
# -------------------------------------------------------------------------

first_character <- function(x) {
  if (is.null(x)) {
    return(NA_character_)
  }
  
  values <- as.character(
    unlist(x, recursive = TRUE, use.names = FALSE)
  )
  
  values <- values[
    !is.na(values) &
      nzchar(values)
  ]
  
  if (length(values) == 0L) {
    NA_character_
  } else {
    values[[1]]
  }
}

first_available <- function(...) {
  values <- unlist(list(...), use.names = FALSE)
  
  values <- as.character(values)
  
  values <- values[
    !is.na(values) &
      nzchar(values)
  ]
  
  if (length(values) == 0L) {
    NA_character_
  } else {
    values[[1]]
  }
}

all_text_values <- function(x) {
  values <- unlist(
    x,
    recursive = TRUE,
    use.names = FALSE
  )
  
  values <- as.character(values)
  
  unique(
    values[
      !is.na(values) &
        nzchar(values)
    ]
  )
}

extract_transcript_annotations <- function(text, transcript) {
  if (length(text) == 0L) {
    return(character())
  }
  
  transcript_pattern <- gsub(
    "\\.",
    "\\\\.",
    transcript
  )
  
  pattern <- paste0(
    transcript_pattern,
    "(?:\\([^)]+\\))?:[cnr]\\.[^[:space:],;()]+"
  )
  
  hits <- str_extract(text, pattern)
  
  unique(hits[!is.na(hits)])
}

extract_protein_candidates <- function(text) {
  if (length(text) == 0L) {
    return(character())
  }
  
  hits <- str_extract(
    text,
    "p\\.(?:\\([^)]*\\)|[^[:space:],;]+)"
  )
  
  hits <- hits[!is.na(hits)]
  
  if (length(hits) == 0L) {
    return(character())
  }
  
  # A title often contains "(p.Arg175His)".
  # Keep HGVS prediction parentheses such as p.(Arg175His),
  # but remove a title-level closing parenthesis.
  hits <- ifelse(
    str_starts(hits, fixed("p.(")),
    hits,
    str_remove(hits, "\\)+$")
  )
  
  unique(hits)
}

extract_protein_position <- function(protein_hgvs) {
  if (is.na(protein_hgvs)) {
    return(NA_integer_)
  }
  
  match <- str_match(
    protein_hgvs,
    "^p\\.\\(?[A-Za-z*?]{1,3}(\\d+)"
  )
  
  suppressWarnings(
    as.integer(match[, 2])
  )
}

extract_record <- function(doc, uid) {
  title <- first_character(doc$title)
  
  accession <- first_available(
    first_character(doc$accession_version),
    first_character(doc$accession),
    uid
  )
  
  classification <- first_character(
    doc$germline_classification$description
  )
  
  review_status <- first_character(
    doc$germline_classification$review_status
  )
  
  # Compatibility fallback for older/different ESummary structures.
  if (is.na(classification)) {
    classification <- first_character(
      doc$clinical_significance$description
    )
  }
  
  if (is.na(review_status)) {
    review_status <- first_character(
      doc$clinical_significance$review_status
    )
  }
  
  record_text <- all_text_values(doc)
  
  transcript_text <- record_text[
    str_detect(
      record_text,
      fixed(transcript_of_interest)
    )
  ]
  
  associated_with_transcript <- length(transcript_text) > 0L
  
  transcript_annotations <- extract_transcript_annotations(
    transcript_text,
    transcript_of_interest
  )
  
  transcript_annotation <- if (
    length(transcript_annotations) > 0L
  ) {
    paste(transcript_annotations, collapse = "; ")
  } else {
    NA_character_
  }
  
  # Prefer a protein HGVS annotation found in the same text as the
  # requested transcript. If none is present there, use a record-wide
  # protein annotation only when it is unambiguous.
  transcript_protein <- extract_protein_candidates(
    transcript_text
  )
  
  if (length(transcript_protein) == 1L) {
    protein_hgvs <- transcript_protein[[1]]
  } else if (length(transcript_protein) > 1L) {
    protein_hgvs <- NA_character_
  } else {
    all_protein <- extract_protein_candidates(
      record_text
    )
    
    protein_hgvs <- if (length(all_protein) == 1L) {
      all_protein[[1]]
    } else {
      NA_character_
    }
  }
  
  protein_position <- extract_protein_position(
    protein_hgvs
  )
  
  tibble(
    clinvar_id = uid,
    accession = accession,
    variant_title = title,
    clinical_classification = classification,
    review_status = review_status,
    transcript = transcript_of_interest,
    associated_with_transcript = associated_with_transcript,
    transcript_annotation = transcript_annotation,
    protein_hgvs = protein_hgvs,
    protein_position = protein_position
  )
}

# -------------------------------------------------------------------------
# 4. Parse ClinVar summaries
# -------------------------------------------------------------------------

clinvar <- map2_dfr(
  summary_docs,
  names(summary_docs),
  extract_record
)

# -------------------------------------------------------------------------
# 5. Apply requested plotting filters
# -------------------------------------------------------------------------

plot_data <- clinvar |>
  filter(
    associated_with_transcript,
    !is.na(clinical_classification),
    nzchar(clinical_classification),
    !is.na(protein_hgvs),
    !is.na(protein_position)
  )

cat(
  sprintf(
    "ClinVar records returned by query: %d\n",
    total_count
  )
)

cat(
  sprintf(
    "ClinVar summaries retrieved: %d\n",
    nrow(clinvar)
  )
)

cat(
  sprintf(
    paste0(
      "Records remaining after filtering for ",
      "%s, clinical classification, ",
      "and identifiable protein position: %d\n"
    ),
    transcript_of_interest,
    nrow(plot_data)
  )
)

if (nrow(plot_data) == 0L) {
  stop("No records remain after filtering.")
}

# -------------------------------------------------------------------------
# 6. Prepare categories and one labelled example per classification
# -------------------------------------------------------------------------

classification_counts <- plot_data |>
  count(
    clinical_classification,
    name = "n"
  ) |>
  arrange(
    desc(n),
    clinical_classification
  )

classification_levels <- classification_counts$clinical_classification

plot_data <- plot_data |>
  mutate(
    clinical_classification = factor(
      clinical_classification,
      levels = classification_levels
    )
  )

classification_labels <- setNames(
  paste0(
    classification_counts$clinical_classification,
    "\n(n=",
    classification_counts$n,
    ")"
  ),
  classification_counts$clinical_classification
)

representative_variants <- plot_data |>
  arrange(
    clinical_classification,
    accession,
    protein_position
  ) |>
  group_by(clinical_classification) |>
  slice_head(n = 1L) |>
  ungroup() |>
  mutate(
    variant_label = if_else(
      !is.na(transcript_annotation),
      paste(
        accession,
        transcript_annotation,
        protein_hgvs,
        sep = "\n"
      ),
      paste(
        accession,
        variant_title,
        protein_hgvs,
        sep = "\n"
      )
    )
  )

# -------------------------------------------------------------------------
# 7. Conference-slide figure
#
# Each row is a clinical classification.
# X position is the amino-acid coordinate on NM_000546.6.
# Point area records multiple ClinVar variants at the same position/class.
# Colour and shape redundantly encode clinical classification.
# -------------------------------------------------------------------------

p <- ggplot(
  plot_data,
  aes(
    x = protein_position,
    y = clinical_classification,
    colour = clinical_classification
  )
) +
  geom_count(
    aes(size = after_stat(n)),
    alpha = 0.82
  ) +
  geom_jitter(
    width = 0,
    height = 0.12,
    alpha = 0.65,
    size = 2.8
  ) +
  ggrepel::geom_label_repel(
    alpha = 0.8,
    data = representative_variants,
    aes(label = variant_label),
    seed = 666,
    size = 3.3,
    nudge_y = 0.6,
    box.padding = 0.45,
    point.padding = 0.25,
    min.segment.length = 0,
    max.overlaps = Inf,
    show.legend = FALSE,
    color = "black"
  ) +
  scale_x_continuous(
    name = paste0(
      gene,
      " amino-acid position (",
      transcript_of_interest,
      ")"
    ),
    breaks = scales::breaks_pretty(n = 8),
    expand = expansion(
      mult = c(0.02, 0.20)
    )
  ) +
  scale_y_discrete(
    name = NULL,
    limits = rev(classification_levels),
    labels = classification_labels
  ) +
  scale_colour_viridis_d(
    option = "D",
    end = 0.90,
    name = "Clinical classification"
  ) +
  scale_size_area(
    name = "Variants\nper position",
    max_size = 7,
    breaks = scales::breaks_pretty(n = 3)
  ) +
  labs(
    title = "TP53 variants in ClinVar",
    subtitle = paste0(
      total_count,
      " records returned; ",
      nrow(plot_data),
      " retained for ",
      transcript_of_interest,
      "\nwith classification and protein position"
    )
  ) +
  guides(
    colour = "none",
    shape = "none",
    size = guide_legend(
      order = 1,
      override.aes = list(alpha = 1)
    )
  ) +
  coord_cartesian(
    clip = "off"
  ) +
  theme_minimal(
    base_size = 17
  ) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 24
    ),
    plot.subtitle = element_text(
      size = 15,
      margin = margin(b = 14)
    ),
    plot.caption = element_text(
      size = 10,
      hjust = 0,
      margin = margin(t = 12)
    ),
    axis.title.x = element_text(
      size = 16,
      margin = margin(t = 10)
    ),
    axis.text.x = element_text(
      size = 13
    ),
    axis.text.y = element_text(
      size = 14
    ),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    legend.position = "right"
  )

ggsave(
  filename = output_file,
  plot = p,
  width = 10,
  height = 6,
  units = "in",
  dpi = 300,
  bg = "white"
)

print(p)
 
