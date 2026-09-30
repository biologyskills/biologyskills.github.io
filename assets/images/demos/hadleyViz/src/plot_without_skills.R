suppressPackageStartupMessages({
  library(httr2)
  library(dplyr)
  library(stringr)
  library(ggplot2)
  library(ggrepel)
})

gene <- "TP53"
transcript_of_interest <- "NM_000546.6"

query <- paste0(
  gene,
  '[gene] AND "reviewed by expert panel"[review status] AND single_gene[prop]'
)

eutils_base <- "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

request_pause <- 0.4
search_page_size <- 1000L
summary_batch_size <- 100L
output_file <- "../output/TP53_ClinVar_expert_reviewed.png"


# NCBI E-utilities ---------------------------------------------------------

eutils_get <- function(endpoint, params) {
  req <- httr2::request(paste0(eutils_base, "/", endpoint))
  
  req <- do.call(
    httr2::req_url_query,
    c(list(.req = req), params)
  )
  
  response <- req |>
    httr2::req_user_agent("TP53-ClinVar-conference-plot/1.0") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform()
  
  httr2::resp_check_status(response)
  
  result <- httr2::resp_body_json(
    response,
    simplifyVector = FALSE
  )
  
  Sys.sleep(request_pause)
  
  result
}


# Helpers -----------------------------------------------------------------

path_get <- function(x, path) {
  for (key in path) {
    if (!is.list(x) || is.null(x[[key]])) {
      return(NULL)
    }
    x <- x[[key]]
  }
  
  x
}

first_nonempty <- function(...) {
  values <- unlist(
    list(...),
    recursive = TRUE,
    use.names = FALSE
  )
  
  if (!length(values)) {
    return(NA_character_)
  }
  
  values <- as.character(values)
  values <- values[!is.na(values)]
  values <- stringr::str_squish(values)
  values <- values[nzchar(values)]
  
  if (!length(values)) {
    return(NA_character_)
  }
  
  values[[1]]
}

flatten_named <- function(x, prefix = "") {
  if (is.null(x)) {
    return(character())
  }
  
  if (is.atomic(x)) {
    values <- as.character(x)
    values <- values[!is.na(values)]
    
    if (!length(values)) {
      return(character())
    }
    
    names(values) <- rep(prefix, length(values))
    return(values)
  }
  
  out <- character()
  nms <- names(x)
  
  for (i in seq_along(x)) {
    key <- if (!is.null(nms) && nzchar(nms[[i]])) {
      nms[[i]]
    } else {
      as.character(i)
    }
    
    child_prefix <- if (nzchar(prefix)) {
      paste(prefix, key, sep = ".")
    } else {
      key
    }
    
    out <- c(
      out,
      flatten_named(x[[i]], child_prefix)
    )
  }
  
  out
}

extract_first <- function(values, pattern) {
  if (!length(values)) {
    return(NA_character_)
  }
  
  hits <- stringr::str_extract(values, pattern)
  hits <- hits[!is.na(hits) & nzchar(hits)]
  
  if (!length(hits)) {
    return(NA_character_)
  }
  
  hits[[1]]
}


# 1. Get total ClinVar record count ----------------------------------------

search_count <- eutils_get(
  "esearch.fcgi",
  list(
    db = "clinvar",
    term = query,
    retmax = 0,
    retmode = "json"
  )
)

total_count <- as.integer(
  search_count$esearchresult$count
)

if (is.na(total_count) || total_count < 1L) {
  stop("The ClinVar query returned no records.")
}


# 2. Retrieve all ClinVar IDs in pages ------------------------------------

retstarts <- seq.int(
  from = 0L,
  to = total_count - 1L,
  by = search_page_size
)

id_pages <- lapply(
  retstarts,
  function(retstart) {
    result <- eutils_get(
      "esearch.fcgi",
      list(
        db = "clinvar",
        term = query,
        retstart = retstart,
        retmax = search_page_size,
        retmode = "json"
      )
    )
    
    unlist(
      result$esearchresult$idlist,
      use.names = FALSE
    )
  }
)

clinvar_ids <- unique(
  unlist(id_pages, use.names = FALSE)
)

if (length(clinvar_ids) != total_count) {
  stop(
    sprintf(
      "Expected %d ClinVar IDs but retrieved %d.",
      total_count,
      length(clinvar_ids)
    )
  )
}


# 3. Retrieve ClinVar summaries in batches --------------------------------

summary_batches <- split(
  clinvar_ids,
  ceiling(seq_along(clinvar_ids) / summary_batch_size)
)

summary_docs <- list()

for (batch in summary_batches) {
  result <- eutils_get(
    "esummary.fcgi",
    list(
      db = "clinvar",
      id = paste(batch, collapse = ","),
      retmode = "json"
    )
  )
  
  uids <- unlist(
    result$result$uids,
    use.names = FALSE
  )
  
  for (uid in uids) {
    summary_docs[[uid]] <- result$result[[uid]]
  }
}

if (length(summary_docs) != length(clinvar_ids)) {
  stop(
    sprintf(
      "Retrieved %d summaries for %d ClinVar IDs.",
      length(summary_docs),
      length(clinvar_ids)
    )
  )
}


# 4. Extract relevant annotations -----------------------------------------

transcript_pattern <- paste0(
  "NM_000546\\.6(?:\\([^)]*\\))?:c\\.[^\\s,;\\(]+"
)

protein_pattern <- paste0(
  "p\\.\\(?",
  "[A-Za-z*?]{1,10}",
  "[0-9]+",
  "[^\\s,;\\)]*",
  "\\)?"
)

protein_position_pattern <- paste0(
  "p\\.\\(?",
  "[A-Za-z*?]{1,10}",
  "([0-9]+)"
)

extract_summary <- function(uid, doc) {
  flat <- flatten_named(doc)
  values <- unname(flat)
  paths <- names(flat)
  
  transcript_values <- values[
    stringr::str_detect(
      values,
      stringr::fixed(transcript_of_interest)
    )
  ]
  
  has_transcript <- length(transcript_values) > 0L
  
  transcript_hgvs <- extract_first(
    transcript_values,
    transcript_pattern
  )
  
  if (!is.na(transcript_hgvs)) {
    transcript_hgvs <- stringr::str_replace(
      transcript_hgvs,
      "^NM_000546\\.6\\([^)]*\\):",
      "NM_000546.6:"
    )
  }
  
  protein_hgvs <- extract_first(
    transcript_values,
    protein_pattern
  )
  
  if (is.na(protein_hgvs)) {
    protein_hgvs <- extract_first(
      values,
      protein_pattern
    )
  }
  
  aa_position <- if (!is.na(protein_hgvs)) {
    match <- stringr::str_match(
      protein_hgvs,
      protein_position_pattern
    )
    
    suppressWarnings(
      as.integer(match[, 2])
    )
  } else {
    NA_integer_
  }
  
  classification_fallback <- values[
    stringr::str_detect(
      paths,
      stringr::regex(
        "(germline_classification|clinical_significance).*description$",
        ignore_case = TRUE
      )
    )
  ]
  
  review_fallback <- values[
    stringr::str_detect(
      paths,
      stringr::regex(
        "(germline_classification|clinical_significance).*review_status$",
        ignore_case = TRUE
      )
    )
  ]
  
  clinical_classification <- first_nonempty(
    path_get(
      doc,
      c("germline_classification", "description")
    ),
    path_get(
      doc,
      c("clinical_significance", "description")
    ),
    classification_fallback
  )
  
  review_status <- first_nonempty(
    path_get(
      doc,
      c("germline_classification", "review_status")
    ),
    path_get(
      doc,
      c("clinical_significance", "review_status")
    ),
    review_fallback
  )
  
  accession <- first_nonempty(
    path_get(doc, c("accession")),
    extract_first(
      values,
      "VCV[0-9]+(?:\\.[0-9]+)?"
    )
  )
  
  variant_title <- first_nonempty(
    path_get(doc, c("title"))
  )
  
  data.frame(
    clinvar_id = uid,
    accession = accession,
    variant_title = variant_title,
    clinical_classification = clinical_classification,
    review_status = review_status,
    transcript_annotation = if (has_transcript) {
      first_nonempty(
        transcript_hgvs,
        transcript_of_interest
      )
    } else {
      NA_character_
    },
    protein_hgvs = protein_hgvs,
    aa_position = aa_position,
    has_transcript = has_transcript,
    stringsAsFactors = FALSE
  )
}

variants <- bind_rows(
  lapply(
    names(summary_docs),
    function(uid) {
      extract_summary(
        uid,
        summary_docs[[uid]]
      )
    }
  )
)


# 5. Filter records for the plot ------------------------------------------

plot_data <- variants |>
  filter(
    has_transcript,
    !is.na(clinical_classification),
    nzchar(clinical_classification),
    !is.na(aa_position)
  ) |>
  distinct(clinvar_id, .keep_all = TRUE)

filtered_count <- nrow(plot_data)

cat(
  sprintf(
    "ClinVar records returned: %d\n",
    total_count
  )
)

cat(
  sprintf(
    paste0(
      "Records retained after filtering to %s\nwith ",
      "a clinical classification and identifiable protein position: %d\n"
    ),
    transcript_of_interest,
    filtered_count
  )
)

if (filtered_count < 1L) {
  stop("No records remained after filtering.")
}


# 6. Order classification categories -------------------------------------

classification_order <- plot_data |>
  count(
    clinical_classification,
    sort = TRUE
  ) |>
  pull(clinical_classification)

plot_data <- plot_data |>
  mutate(
    clinical_classification = factor(
      clinical_classification,
      levels = rev(classification_order)
    )
  )


# 7. Take one representative variant from each classification -------------

label_data <- plot_data |>
  arrange(
    clinical_classification,
    aa_position,
    clinvar_id
  ) |>
  group_by(clinical_classification) |>
  slice_head(n = 1L) |>
  ungroup() |>
  mutate(
    display_accession = if_else(
      is.na(accession),
      paste0("ClinVar ", clinvar_id),
      accession
    ),
    display_transcript = if_else(
      is.na(transcript_annotation),
      transcript_of_interest,
      transcript_annotation
    ),
    display_protein = if_else(
      is.na(protein_hgvs),
      paste0("AA ", aa_position),
      protein_hgvs
    ),
    variant_label = paste(
      display_accession,
      display_transcript,
      display_protein,
      sep = "\n"
    )
  )


# 8. Plot -----------------------------------------------------------------

p <- ggplot(
  plot_data,
  aes(
    x = aa_position,
    y = clinical_classification,
    colour = clinical_classification
  )
) +
  geom_jitter(
    width = 0,
    height = 0.12,
    alpha = 0.65,
    size = 2.8
  ) +
  geom_point(
    data = label_data,
    size = 3.8
  ) +
  ggrepel::geom_label_repel(
    data = label_data,
    aes(label = variant_label),
    seed = 1,
    box.padding = 0.5,
    point.padding = 0.4,
    min.segment.length = 0,
    max.overlaps = Inf,
    force = 1,
    size = 3.2,
    alpha = 0.8,
    lineheight = 0.95,
    label.size = 0.2,
    show.legend = FALSE
  ) +
  scale_x_continuous(
    name = "TP53 amino-acid position",
    breaks = scales::breaks_pretty(n = 8),
    expand = expansion(
      mult = c(0.02, 0.18)
    )
  ) +
  labs(
    title = "TP53 variants in ClinVar",
    subtitle = sprintf(
      paste0(
        "Query returned %s records; %s remained after filtering ",
        "to %s \nwith clinical classification and protein position"
      ),
      format(total_count, big.mark = ","),
      format(filtered_count, big.mark = ","),
      transcript_of_interest
    ),
    y = NULL
  ) +
  guides(
    colour = "none"
  ) +
  theme_minimal(
    base_size = 16
  ) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    axis.text.y = element_text(
      size = 12
    ),
    plot.title = element_text(
      face = "bold",
      size = 22
    ),
    plot.subtitle = element_text(
      size = 12,
      margin = margin(
        b = 16
      )
    ),
    plot.margin = margin(
      20,
      30,
      20,
      20
    )
  )

ggsave(
  filename = output_file,
  plot = p,
  width = 8,
  height = 5,
  units = "in",
  dpi = 300,
  bg = "white"
)
