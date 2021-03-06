#' Download shape files of meso region as sf objects. Data at scale 1:250,000, using Geodetic reference system "SIRGAS2000" and CRS(4674)
#'
#' Data at scale 1:250,000, using Geodetic reference system "SIRGAS2000" and CRS(4674)
#'
#' @param year Year of the data (defaults to 2010)
#' @param code_meso The 4-digit code of a meso region. If the two-digit code or a two-letter uppercase abbreviation of
#'  a state is passed, (e.g. 33 or "RJ") the function will load all meso regions of that state. If code_meso="all", all meso regions of the country are loaded.
#' @param tp Whether the function returns the 'original' dataset with high resolution or a dataset with 'simplified' borders (Default)
#' @export
#' @family general area functions
#' @examples \donttest{
#'
#' library(geobr)
#'
#' # Read specific meso region at a given year
#'   meso <- read_meso_region(code_meso=3301, year=2018)
#'
#' # Read all meso regions of a state at a given year
#'   meso <- read_meso_region(code_meso=12, year=2017)
#'   meso <- read_meso_region(code_meso="AM", year=2000)
#'
#' # Read all meso regions of the country at a given year
#'   meso <- read_meso_region(code_meso="all", year=2010)
#'
#' }
#'

read_meso_region <- function(code_meso="all", year=NULL, tp="simplified"){


  # Get metadata with data addresses
  metadata <- download_metadata()


  # Select geo
  temp_meta <- subset(metadata, geo=="meso_region")

  # Select data type
  temp_meta <- select_data_type(temp_meta, tp)

  # Verify year input
  if (is.null(year)){ message("Using data from year 2010\n")
    temp_meta <- subset(temp_meta, year==2010)

  } else if (year %in% temp_meta$year){ temp_meta <- temp_meta[temp_meta[,2] == year, ]

  } else { stop(paste0("Error: Invalid Value to argument 'year'. It must be one of the following: ",
                       paste(unique(temp_meta$year),collapse = " ")))
  }


# Verify code_meso input

  # if code_meso=="all", read the entire country
  if(code_meso=="all"){ message("Loading data for the whole country\n")

    # list paths of files to download
    filesD <- as.character(temp_meta$download_path)

    # input for progress bar
      total <- length(filesD)
      pb <- utils::txtProgressBar(min = 0, max = total, style = 3)

    # download files
      lapply(X=filesD, function(x){
                                    i <- match(c(x),filesD)
                                    httr::GET(url=x, #httr::progress(),
                                            httr::write_disk(paste0(tempdir(),"/", unlist(lapply(strsplit(x,"/"),tail,n=1L))), overwrite = T))
                                    utils::setTxtProgressBar(pb, i)
                                  }
             )
    # closing progress bar
      close(pb)

    # read files and pile them up
    files <- unlist(lapply(strsplit(filesD,"/"), tail, n = 1L))
    files <- paste0(tempdir(),"/",files)
    files <- lapply(X=files, FUN= sf::st_read, quiet=T)
    shape <- do.call('rbind', files)
    return(shape)
  }

  if( !(substr(x = code_meso, 1, 2) %in% temp_meta$code) & !(substr(x = code_meso, 1, 2) %in% temp_meta$code_abrev)){
    stop("Error: Invalid Value to argument code_meso.")

  } else{

    # list paths of files to download
    if (is.numeric(code_meso)){ filesD <- as.character(subset(temp_meta, code==substr(code_meso, 1, 2))$download_path) }
    if (is.character(code_meso)){ filesD <- as.character(subset(temp_meta, code_abrev==substr(code_meso, 1, 2))$download_path) }



    # download files
    temps <- download_gpkg(filesD)

    # read sf
    shape <- sf::st_read(temps, quiet=T)

    if(nchar(code_meso)==2){
      return(shape)

    } else if(code_meso %in% shape$code_meso){    # Get meso region
      x <- code_meso
      shape <- subset(shape, code_meso==x)
      return(shape)
    } else{
      stop("Error: Invalid Value to argument code_meso.")
    }
  }
}
