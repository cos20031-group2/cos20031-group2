<?php
// Renders numbered page links (with a sliding window around the current page),
// preserving every other GET parameter already on the page (filters, other
// tables' page numbers) so switching pages never resets anything else.
function paginationControls(int $currentPage, int $totalPages, string $pageParam): string
{
    if ($totalPages <= 1) {
        return '';
    }

    $baseParams = $_GET;
    $linkFor = function (int $p) use ($baseParams, $pageParam): string {
        $params = $baseParams;
        $params[$pageParam] = $p;
        return '?' . htmlspecialchars(http_build_query($params));
    };

    $window = 2;
    $start = max(1, $currentPage - $window);
    $end = min($totalPages, $currentPage + $window);

    $html = '<nav class="pagination">';

    if ($currentPage > 1) {
        $html .= '<a href="' . $linkFor($currentPage - 1) . '">&lsaquo; Prev</a>';
    }

    if ($start > 1) {
        $html .= '<a href="' . $linkFor(1) . '">1</a>';
        if ($start > 2) {
            $html .= '<span>&hellip;</span>';
        }
    }

    for ($p = $start; $p <= $end; $p++) {
        if ($p === $currentPage) {
            $html .= '<span class="current-page">' . $p . '</span>';
        } else {
            $html .= '<a href="' . $linkFor($p) . '">' . $p . '</a>';
        }
    }

    if ($end < $totalPages) {
        if ($end < $totalPages - 1) {
            $html .= '<span>&hellip;</span>';
        }
        $html .= '<a href="' . $linkFor($totalPages) . '">' . $totalPages . '</a>';
    }

    if ($currentPage < $totalPages) {
        $html .= '<a href="' . $linkFor($currentPage + 1) . '">Next &rsaquo;</a>';
    }

    $html .= '</nav>';
    return $html;
}

// Reads the current page number for a given page-parameter name, defaulting to 1
// and guarding against zero/negative/non-numeric values from a tampered URL.
function currentPage(string $pageParam): int
{
    $page = (int)($_GET[$pageParam] ?? 1);
    return $page < 1 ? 1 : $page;
}
